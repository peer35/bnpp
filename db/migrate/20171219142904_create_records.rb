class CreateRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :records do |t|
      t.string :bnpp_id
      t.text :titel
      t.text :ondertitel
      t.text :categorie
      t.text :verschenen
      t.text :eigenaar
      t.text :uitgever
      t.text :drukker
      t.text :uitgave
      t.text :frequentie
      t.text :omvang
      t.text :formaat
      t.text :oplage
      t.text :prijzen
      t.text :fotos
      t.text :tekeningen
      t.text :redactie
      t.text :medewerkers
      t.text :speciale
      t.text :biblio
      t.text :autopsie
      t.text :achtergrond
      t.text :literatuur
      t.text :vindplaats

      t.timestamps
    end
  end
end
