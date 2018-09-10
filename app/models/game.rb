class Game
  include Mongoid::Document
  field :history, type: Array
  field :status, type: String, default: ->{ "waiting" }
  field :winner, type: BSON::ObjectId
  field :loser, type: BSON::ObjectId

  has_and_belongs_to_many :users

  validates :status, inclusion: { in: %w(waiting playing finished),
    message: "%{value} is not a valid status"}
  validates :user_ids, presence: true, length: { minimum: 1, maximum: 2,
    message: "Minimum of 1 user while waiting and 2 to play" }

  def destroy
    raise "Cannot delete Game which is not waiting" if self.status != "waiting"
    super
  end

end
