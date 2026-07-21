class Card < ApplicationRecord
  belongs_to :column
  belongs_to :assignee, class_name: "User", optional: true

  acts_as_list scope: :column

  PRIORITIES = %w[low medium high urgent].freeze
  LABEL_COLORS = %w[#f87171 #fb923c #fbbf24 #facc15 #a3e635 #4ade80 #34d399 #2dd4bf #22d3ee #38bdf8 #60a5fa #818cf8 #a78bfa #c084fc #e879f9 #f472b6 #fb7185].freeze

  validates :title, presence: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true
  validates :custom_fields, presence: true, json: { allow_blank: false }

  store_accessor :custom_fields

  def label_list
    labels.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def label_color(label)
    index = label.bytes.sum % LABEL_COLORS.size
    LABEL_COLORS[index]
  end

  def text_color_for_bg(bg_hex)
    r, g, b = bg_hex.match(/#(\h{2})(\h{2})(\h{2})/).captures.map(&:hex)
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    luminance > 0.5 ? "#000000" : "#FFFFFF"
  end
end