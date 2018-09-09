class Game
  include Mongoid::Document
  field :history, type: Array
  field :status, type: String, default: ->{ "waiting" }
  field :winner, type: BSON::ObjectId
  field :loser, type: BSON::ObjectId

  has_and_belongs_to_many :users

  validates :status, inclusion: { in: %w(waiting playing finished),
    message: "%{value} is not a valid status"}
  validates :users, length: { minimum: 1, maximum: 2,
    message: "Minimum of 1 player while waiting and 2 to play" }

end
