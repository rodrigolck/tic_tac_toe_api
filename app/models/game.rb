class Game
  include Mongoid::Document
  field :history, type: Array, default: -> { [{"game_state"=>[[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]], "turn"=> nil}] }
  field :status, type: String, default: -> { "waiting" }
  field :winner, type: BSON::ObjectId
  field :loser, type: BSON::ObjectId

  has_and_belongs_to_many :users

  validates :status, inclusion: { in: %w(waiting playing finished),
    message: "%{value} is not a valid status"}
  validates :user_ids, presence: true, length: { minimum: 1, maximum: 2,
    message: "Minimum of 1 user while waiting and 2 to play" }

  def destroy(user)
    raise "Cannot delete Game which is not waiting" if self.status != "waiting"
    raise "Cannot delete Game which current user does not take part" if user_hash.keys.exclude?(user.id.to_s)
    super
  end

  def move(move, user)
    raise "Invalid move" if invalid_move?(move, user)
    self.update_attributes!(status: "playing") if status == "waiting"
    last_game_state = clone_last_game_state
    last_game_state[move.first][move.last] = user.id.to_s
    self.history << {"game_state" => last_game_state, "turn" => user.id.to_s}
    self.update_attributes!(history: self.history)
    finish
  end

  def finish
    self.update_attributes!(status: "finished") if all_filled?
    winner_id = winner_id_of_game
    if winner_id
      loser_id = user_hash.keys.last.to_s if self.user_ids.first.to_s == winner_id
      loser_id ||= user_hash.keys.first.to_s
      self.update_attributes!(status: "finished", winner: winner_id, loser: loser_id)
    end
  end

  def game_json(history = false)
    result =
      {
        id: self.id.to_s,
        status: self.status,
        users: self.users.map {|user| user.name},
        winner: user_hash[self.winner.to_s].try(:name),
        loser: user_hash[self.loser.to_s].try(:name)
      }
    result[:history] = history_json if history
    result
  end

  private
    def clone_last_game_state
      self.history.last["game_state"].map{|game_line| game_line.dup}
    end

    def history_json
      self.history.map do |game_hist|
        {
          game_state: game_state_json(game_hist["game_state"]),
          turn: user_hash[game_hist["turn"]].try(:name)
        }
      end
    end
    
    def game_state_json(game_state)
      game_state.map do |line|
        line.map do |slot|
          user_hash[slot].try(:name)
        end
      end
    end

    def invalid_move?(move, user)
      self.status == "finished" ||
      self.history.last["turn"] == user.id.to_s ||
      self.history.last["game_state"][move.first][move.last] ||
      !user_hash[user.id.to_s] ||
      move.class != Array ||
      move.size != 2 ||
      (move.first < 0 && move.first > 3) ||
      (move.last < 0 && move.last > 3)
    end

    def all_filled?
      self.history.last["game_state"].flatten.all?
    end

    def winner_id_of_game
      flattened_game = self.history.last["game_state"].flatten
      return flattened_game[0] if all_equal?(flattened_game, 0, 1, 2)
      return flattened_game[3] if all_equal?(flattened_game, 3, 4, 5)
      return flattened_game[6] if all_equal?(flattened_game, 6, 7, 8)
      return flattened_game[0] if all_equal?(flattened_game, 0, 3, 6)
      return flattened_game[1] if all_equal?(flattened_game, 1, 4, 7)
      return flattened_game[2] if all_equal?(flattened_game, 2, 5, 8)
      return flattened_game[0] if all_equal?(flattened_game, 0, 4, 8)
      return flattened_game[2] if all_equal?(flattened_game, 2, 4, 6)
    end

    def all_equal?(flattened_game, v1, v2, v3)
      flattened_game[v1] == flattened_game[v2] && flattened_game[v2] == flattened_game[v3]
    end

    def user_hash
      return @user_hash if @user_hash
      @user_hash = Hash.new
      users_array = self.users.to_a
      @user_hash[users_array.first.id.to_s] = users_array.first
      @user_hash[users_array.last.id.to_s] = users_array.last
      @user_hash
    end

end
