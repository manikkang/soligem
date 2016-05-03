module Spree
  class OptionValue < Spree::Base
    belongs_to :option_type, class_name: 'Spree::OptionType', inverse_of: :option_values
    acts_as_list scope: :option_type
     has_many :optionvalue_labels
    has_many :labels ,through: :optionvalue_labels
    
     
    has_many :option_values_variants, dependent: :destroy
    has_many :variants, through: :option_values_variants
     has_attached_file :photo, styles: { medium: "300x300>", thumb: "100x100>", circle: "50x50>" }, default_url: "/images/:style/missing.png"
  validates_attachment :photo,
  content_type: { content_type: ["image/jpeg", "image/gif", "image/png"] }
    
    validates :name, presence: true, uniqueness: { scope: :option_type_id, allow_blank: true }
    validates :presentation, presence: true

    after_save :touch, if: :changed?
    after_touch :touch_all_variants

    delegate :name, :presentation, to: :option_type, prefix: :option_type

    self.whitelisted_ransackable_attributes = ['presentation']

    # Updates the updated_at column on all the variants associated with this
    # option value.
    def touch_all_variants
      variants.find_each(&:touch)
    end

    # @return [String] a string representation of all option value and its
    #   option type
    def presentation_with_option_type
      "#{option_type.presentation} - #{presentation}"
    end
  end
end
