class CreateInputDocs < ActiveRecord::Migration[6.0]
  def change
    create_table :input_docs do |t|
      t.string :name
      t.string :attachment

      t.timestamps
    end
  end
end
