class GamesController < ApplicationController
  before_action :set_game, only: [:show, :update, :destroy]

  # GET /games
  def index
    @games = Game.where(game_params).to_a
    render json: { games: index_games_json(@games)}
  end

  # GET /games/1
  def show
    render json: game_json(@game, true)
  end

  # POST /games
  def create
    if Game.where(status: {"$in": ["waiting", "playing"]}, user_ids: current_user.id).count > 0
      return render json: {errors: ["Current User already in Game"]}, status: :unprocessable_entity
    end
    @game = Game.new(user: [current_user])

    if @game.save
      render json: @game, status: :created, location: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /games/1
  def update
    if @game.update(game_params)
      render json: @game
    else
      render json: @game.errors, status: :unprocessable_entity
    end
  end

  # DELETE /games/1
  def destroy
    begin
      @game.destroy
      render status: :no_content
    rescue StandardError => ex
      return render json: {game: [ex.message]}, status: :unprocessable_entity
    end
  end

  private
    def index_games_json(games)
      games.map {|game| game_json(game)}
    end

    def game_json(game, history = false)
      result =
        {
          id: game.id.to_s,
          status: game.status,
          users: game.users.map {|user| user.name},
          winner: game.winner,
          loser: game.loser
        }
      result[:history] = game.history if history
      result
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def game_params
      params.permit(:status)
    end
end
