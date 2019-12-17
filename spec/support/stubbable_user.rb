# Convenience methods for stubbing current user
module StubbableUser
  module ClassMethods
    def stub=(user)
      @stub = user
    end

    def authenticate!(options = {})
      css_id = options[:css_id] || "123123"
      user_name = options[:user_name] || "first last"
      Functions.grant!("System Admin", users: [css_id]) if options[:roles]&.include?("System Admin")

      self.stub = find_or_create_by(css_id: css_id, station_id: "116").tap do |u|
        u.name = user_name
        u.email = "test@gmail.com"
        u.roles = options[:roles] || ["Download eFolder"]
        u.save
        RequestStore.store[:current_user] = u
      end
    end

    def tester!(options = {})
      self.stub = find_or_create_by(css_id: ENV["TEST_USER_ID"], station_id: "116").tap do |u|
        u.name = "first last"
        u.email = "test@gmail.com"
        u.roles = options[:roles] || ["Download eFolder"]
        u.save
      end
    end

    def unauthenticate!
      Functions.delete_all_keys!
      RequestStore.store[:current_user] = nil
      self.stub = nil
    end

    def from_session_and_request(session, request)
      @stub || super(session, request)
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end
end
User.prepend(StubbableUser)
