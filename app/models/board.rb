class Board < ApplicationRecord
  has_many :columns, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true
end
