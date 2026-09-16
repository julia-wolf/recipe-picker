class IngredientParser
  class Quantity
    GLYPHS = {
      "½" => 1/2r,
      "¼" => 1/4r,
      "¾" => 3/4r,
      "⅓" => 1/3r,
      "⅔" => 2/3r,
      "⅛" => 1/8r,
      "⅜" => 3/8r,
      "⅝" => 5/8r,
      "⅞" => 7/8r
    }.freeze

    GLYPH = /[#{GLYPHS.keys.map { |char| Regexp.escape(char) }.join}]/
    SLASHED = /\d+\s*[\/\u2044]\s*\d+/
    PATTERN = /
      \A
      (?:
        (?<whole>\d+)\s+(?<mixed>#{SLASHED}|#{GLYPH})
        |
        (?<fraction>#{SLASHED}|#{GLYPH})
        |
        (?<plain>\d*\.\d+|\d+)
      )
      \s*
    /x

    class << self
      def extract(text)
        match = PATTERN.match(text)
        return [ nil, text ] unless match

        quantity =
          if match[:whole]
            match[:whole].to_r + fraction(match[:mixed])
          elsif match[:fraction]
            fraction(match[:fraction])
          elsif match[:plain].include?(".")
            match[:plain].to_f
          else
            match[:plain].to_r
          end

        [ quantity, match.post_match ]
      end

      private

      def fraction(frac)
        GLYPHS.fetch(frac) { frac.gsub(/\s+/, "").tr("\u2044", "/").to_r }
      end
    end
  end
end
