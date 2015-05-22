class School < ActiveRecord::Base
  include DetailsHash
  include AlphabeticalOrder

  OUTDATED_IF_OLDER_THAN = 2.months

  belongs_to :town
  has_many :events

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable

  details_attribute :visit_dates
  details_attribute :remarks
  details_attribute :disciplines,         any_of: Options.for('disciplines').keys.map(&:to_s)
  details_attribute :available_equipment, any_of: Options.for('available_equipment').keys.map(&:to_s)
  details_attribute :meetup_options,      one_of: Options.for('meetup_options').keys.map(&:to_s)

  delegate :state, :municipality, to: :town

  validates :name, presence: true, uniqueness: {scope: :town_id}
  validates :town_id, presence: true
  validates :address, presence: true
  validates :contact_name, presence: true
  validates :email, email: true, allow_blank: true
  validates :visit_dates, presence: true
  validates :disciplines, presence: true
  validates :meetup_options, presence: true
  validates :confirmed_participation, acceptance: {accept: true}, if: :new_record?

  scope :participating, -> { where(confirmed_participation: true) }
  scope :not_participating, -> { where(confirmed_participation: false) }
  scope :with_location_info, -> { includes(town: {municipality: :state}) }
  scope :outdated, -> { where(arel_table[:updated_at].lt(OUTDATED_IF_OLDER_THAN.ago)) }
  scope :up_to_date, -> { where(arel_table[:updated_at].gteq(OUTDATED_IF_OLDER_THAN.ago)) }
  scope :with_events, -> { where(arel_table[:events_count].gt(0)) }
  scope :no_events, -> { where(events_count: 0) }

  geocoded_by :address_for_geocoding
  after_validation :geocode, if: proc { address_for_geocoding.present? && address_for_geocoding_changed? }

  def pending_events
    events.pending
  end

  def outdated?
    updated_at < OUTDATED_IF_OLDER_THAN.ago
  end

  def up_to_date?
    !outdated?
  end

  def person_name
    contact_name
  end

  def name_with_location
    "#{name}, #{town.full_name}"
  end

  def email_with_name
    "#{contact_name} <#{email}>"
  end

  def full_address
    "#{town.full_name}, #{address}" if town
  end

  def address_for_geocoding
    "#{address}, #{town.name_with_kind}, #{state.name}, България" if town
  end

  def address_for_geocoding_changed?
    town_id_changed? || address_changed?
  end
end
