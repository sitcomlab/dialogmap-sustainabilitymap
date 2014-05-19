class Contribution < ActiveRecord::Base
  has_many :features
  has_many :references

  accepts_nested_attributes_for :features, :references

  validates_presence_of :title, :description

  after_create :transform_description

  scope :within, -> (bbox_string) {
    where(id: Feature.within(bbox_string).map { |f| f.contribution_id })
  }

  private
    def transform_description
      # when creating contributions, the description contains references to
      # features that don't exist yet..

      # create a hash that contains the substitutions
      substitutions = self.features.map { |f| [ "%[#{f.leaflet_id}]%", "%[#{f.id}]%" ]}.to_h
      #substitute..
      self.description.gsub! /%\[\d+\]%/, substitutions
    end

end
