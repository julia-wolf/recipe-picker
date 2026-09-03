class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.text :image_url
      t.integer :prep_time
      t.integer :cook_time
      t.decimal :rating, precision: 3, scale: 2
      t.string :category
      t.string :author

      t.timestamps
    end
  end
end
