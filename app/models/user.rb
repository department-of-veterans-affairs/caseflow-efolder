# frozen_string_literal: true
class User < ActiveRecord::Base
  has_many :searches
  has_many :downloads
  # v2 relationship
  has_many :user_manifests
  has_many :manifests, through: :user_manifests

  validates :css_id, uniqueness: { scope: :station_id, case_sensitive: false }

  before_save { |u| u.email.try(:strip!) }

  NO_EMAIL = "No Email Recorded".freeze

  attr_accessor :name, :roles, :ip_address

  def display_name
    return "Unknown" if name.nil?
    name
  end

  # We should not use user.can?("System Admin"), but user.admin? instead
  def can?(function)
    return true if admin?
    # Check if user is granted the function
    return true if granted?(function)
    # Check if user is denied the function
    return false if denied?(function)
    # Ignore "System Admin" function from CSUM/CSEM users
    return false if function.include?("System Admin")
    roles ? roles.include?(function) : false
  end

  def admin?
    Functions.granted?("System Admin", css_id)
  end

  def granted?(thing)
    Functions.granted?(thing, css_id)
  end

  def denied?(thing)
    Functions.denied?(thing, css_id)
  end

  class << self
    def from_session(session, request)
      return nil unless session["user"]
      user = session["user"]
      find_or_create_by(css_id: user["css_id"], station_id: user["station_id"]).tap do |u|
        u.name = user["name"]
        u.email = user["email"]
        u.roles = user["roles"]
        u.ip_address = request.remote_ip
        u.save
      end
    end

    def from_css_auth_hash(auth_hash)
      raw_css_response = auth_hash.extra.raw_info
      first_name = raw_css_response["http://vba.va.gov/css/common/fName"]
      last_name = raw_css_response["http://vba.va.gov/css/common/lName"]

      {
        id: auth_hash.uid,
        css_id: auth_hash.uid,
        email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
        name: "#{first_name} #{last_name}",
        roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
        station_id: raw_css_response["http://vba.va.gov/css/common/stationId"]
      }
    end

    # TODO: (lowell) Re-implement ActiveRecord's find_or_create_by() method in order to properly call find_by()
    # from within find_or_create_by() since ActiveRecord::Relation.find_or_create_by() (by way of ActiveRecord::Base?)
    # is not calling User.find_by() as I expected it would. Perhaps this is because of some way ruby/ActiveRecord
    # handles inheritance and child class method overriding? It does not appear as if ActiveRecord::Relation is an
    # abstract class that ActiveRecord::Base implements, but then I still do not fully understand how rails does all
    # of its magic.
    #
    # Link to ActiveRecord::Relation's find_or_create_by() implementation:
    # https://apidock.com/rails/v4.0.2/ActiveRecord/Relation/find_or_create_by
    #
    # One other thought is that our reliance on hijacking a library's internal implementation details to accomplish
    # our objective (that is, this fix relies on the ActiveRecord::Relation.find_or_create_by() calling find_by() and
    # will fail should that internal implementation detail change this fix will fail to function) may indicate that
    # we are solving this in a less-than-ideal fashion and we should consider better/easier/more direct solutions.
    def find_or_create_by(attributes, &block)
      find_by(attributes) || create(attributes, &block)
    end

    def find_by(args)
      attrs = args.clone
      # If css_id is an argument, remove it from the list so we can search
      # case-insensitively on css_id in ther second where clause.
      conditions = []
      if attrs[:css_id]
        conditions = ["upper(css_id) = upper(?)", attrs[:css_id]]
        attrs.delete(:css_id)
      end

      where(attrs).where(conditions).first
    end
  end
end
