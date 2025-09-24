class Column < ApplicationRecord
  belongs_to :collection
  has_many :cards, dependent: :nullify

  validates :name, presence: true
  validates :color, presence: true
end