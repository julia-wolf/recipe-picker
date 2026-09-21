require "json"
require "net/http"
require "openssl"
require "stringio"
require "uri"
require "zlib"

class RecipeImporter
  DATASET_URL = "https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz".freeze
  BATCH_SIZE = 1_000

  def self.import(source = DATASET_URL)
    new(source).import
  end

  def initialize(source)
    @source = source
  end

  def import
    payload = JSON.parse(read_json)
    raise ArgumentError, "Expected an array of recipes" unless payload.is_a?(Array)

    ActiveRecord::Base.transaction do
      clear!
      persist(payload)
    end
  end

  private

  def read_json
    bytes = remote? ? fetch_remote : read_local
    gzip?(bytes) ? Zlib::GzipReader.new(StringIO.new(bytes)).read : bytes
  end

  def remote?
    @source.to_s.start_with?("http://", "https://")
  end

  def read_local
    path = Pathname(@source)
    raise ArgumentError, "Missing dataset: #{path}" unless path.exist?

    path.binread
  end

  def fetch_remote
    uri = URI.parse(@source.to_s)
    allowed = URI.parse(DATASET_URL)
    unless uri.scheme == allowed.scheme && uri.host == allowed.host && uri.path == allowed.path
      raise ArgumentError, "Remote import only supports the official dataset URL"
    end

    response = http_get(uri, ssl_ca_file)
    unless response.is_a?(Net::HTTPSuccess)
      raise ArgumentError, "Could not download dataset (#{response.code}): #{@source}"
    end

    response.body
  end

  def http_get(uri, ca_file)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ca_file = ca_file if ca_file
    http.request(Net::HTTP::Get.new(uri))
  end

  def ssl_ca_file
    [
      ENV["SSL_CERT_FILE"],
      (OpenSSL::X509::DEFAULT_CERT_FILE rescue nil),
      "/usr/local/etc/ca-certificates/cert.pem",
      "/etc/ssl/cert.pem"
    ].compact.find { |path| File.file?(path) }
  end

  def gzip?(bytes)
    bytes.byteslice(0, 2) == "\x1F\x8B".b
  end

  def clear!
    RecipeIngredient.delete_all
    Recipe.delete_all
    Ingredient.delete_all
    %w[recipe_ingredients recipes ingredients].each do |table|
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end
  end

  def persist(payload)
    now = Time.current
    parsed_recipes = payload.filter_map { |row| build_recipe(row, now) }
    return if parsed_recipes.empty?

    ingredient_rows = unique_ingredient_rows(parsed_recipes, now)
    insert_in_batches(Ingredient, ingredient_rows)
    ingredient_ids = Ingredient.pluck(:normalized_name, :id).to_h

    recipe_ids = insert_in_batches(
      Recipe,
      parsed_recipes.map { |item| item[:recipe] },
      returning: %w[id]
    )

    join_rows = parsed_recipes.flat_map.with_index do |item, index|
      item[:lines].filter_map do |line|
        ingredient_id = ingredient_ids[line[:normalized_name]]
        next unless ingredient_id

        {
          recipe_id: recipe_ids[index],
          ingredient_id: ingredient_id,
          display_text: line[:display_text],
          created_at: now,
          updated_at: now
        }
      end
    end

    insert_in_batches(RecipeIngredient, join_rows)
  end

  def insert_in_batches(model, rows, returning: nil)
    return [] if rows.empty?

    rows.each_slice(BATCH_SIZE).flat_map do |slice|
      options = { record_timestamps: false }
      options[:returning] = returning if returning
      result = model.insert_all(slice, **options)
      returning ? result.rows.flatten : []
    end
  end

  def build_recipe(row, now)
    title = row["title"].to_s.strip
    return if title.empty?

    lines = Array(row["ingredients"]).filter_map { |raw| build_line(raw) }

    {
      recipe: {
        title: title,
        image_url: unwrap_image_url(row["image"]),
        prep_time: row["prep_time"],
        cook_time: row["cook_time"],
        rating: row["ratings"],
        category: row["category"].presence,
        author: row["author"].presence,
        created_at: now,
        updated_at: now
      },
      lines: lines
    }
  end

  def unwrap_image_url(raw)
    url = raw.to_s.strip
    return if url.blank?

    uri = URI.parse(url)
    inner = URI.decode_www_form(uri.query.to_s).assoc("url")&.last
    inner.presence || url
  rescue URI::InvalidURIError
    url
  end

  def build_line(raw)
    parsed = IngredientParser.parse(raw)
    normalized_name = IngredientNormalizer.call(parsed.name)
    return if normalized_name.blank?

    {
      normalized_name: normalized_name,
      name: parsed.name,
      display_text: UnitConverter.display_text(parsed)
    }
  end

  def unique_ingredient_rows(parsed_recipes, now)
    parsed_recipes.each_with_object({}) do |item, unique|
      item[:lines].each do |line|
        unique[line[:normalized_name]] ||= {
          name: line[:name],
          normalized_name: line[:normalized_name],
          created_at: now,
          updated_at: now
        }
      end
    end.values
  end
end
