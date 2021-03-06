require 'color'
class Feature < ActiveRecord::Base
  # see api.rubyonrails.org/classes/ActiveRecord/ModelSchema/ClassMethods.html#method-i-inheritance_column
  self.inheritance_column = 'inheritance_column'
  set_rgeo_factory_for_column(:geom, RGeo::Geographic.spherical_factory(:srid => 4326))
  attr_accessor :geojson
  attr_accessor :leaflet_id
  hstore_accessor :properties, #simplestyle-spec github.com/mapbox/simplestyle-spec
    :title            => :string,
    :description      => :string,
    :"marker-size"    => :string,
    :"marker-symbol"  => :string,
    :"marker-color"   => :string,
    :stroke           => :string,
    :"stroke-opacity" => :float,
    :"stroke-width"   => :float,
    :fill             => :string,
    :"fill-opacity"   => :float

  before_validation :decode_geojson_from_params, if: :geojson_present?

  scope :within, -> (bbox_string) {
    bbox_array = bbox_string.split(",")
    factory = RGeo::Geographic.spherical_factory(:srid => 4326)
    sw = factory.point(bbox_array[0], bbox_array[1])
    ne = factory.point(bbox_array[2], bbox_array[3])
    window = RGeo::Cartesian::BoundingBox.create_from_points(sw, ne).to_geometry
    where("geom && ?", window)
  }

  def attributes
    {
      'id' => nil,
      'type' => nil,
      'geometry' => nil,
      'properties' => nil
    }
  end

  def geometry
    RGeo::GeoJSON.encode(self.geom)
  end

  # overwritten
  def type
    'Feature'
  end

  # augment the properties hash for better handling
  def properties
    props = super
    props.merge! :contribution_id => self.contribution_id unless props.has_key? :contribution_id
    props.merge! :id => self.id unless props.has_key? :id
    props
  end

  def update_from_geojson(geojson)
    self.geojson = geojson
    decode_geojson_from_params
    self.save!
  end

  def lighten_colors
    value = 65
    self.update({
      :"marker-color" => Color::RGB.by_hex(self.send("marker-color")).lighten_by(value).html
      }) unless self.send("marker-color") == nil
    self.update({
        stroke: Color::RGB.by_hex(self.stroke).lighten_by(value).html,
        fill: Color::RGB.by_hex(self.fill).lighten_by(value).html
      }) unless self.stroke == nil or self.fill == nil
  end

  def update_color(color, deleted)
    color = Color::RGB.by_hex(color).lighten_by(65).html if deleted
    self.update({
      :"marker-color" => color
      }) unless self.send("marker-color") == nil
    self.update({
        stroke: color,
        fill: color
      }) unless self.stroke == nil or self.fill == nil
  end

  private
    def decode_geojson_from_params
      geojson = RGeo::GeoJSON.decode(self.geojson, :json_parser => :json)
      self.geom = geojson.geometry
      self.properties = geojson.properties
      self.id = geojson.properties["id"] if geojson.properties["id"] != nil
      self.errors.add(:geojson, "invalid GeoJSON") unless self.geom
    end

    def geojson_present?
      self.geojson != nil
    end

end
