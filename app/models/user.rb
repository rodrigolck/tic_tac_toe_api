class User
  include Mongoid::Document
  include BCrypt
  field :name, type: String
  field :email, type: String
  field :password_hash, type: String

  has_and_belongs_to_many :games

  validates_presence_of :name, :email, :password_hash

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def self.find_by_email(email)
    User.find_by(email: email)
  end
end
