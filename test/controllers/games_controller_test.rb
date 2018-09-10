require 'test_helper'

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Game.delete_all
    User.delete_all
    @user = User.create(name: "Test", email: "test@test.com", password: "123123123")
    @user2 = User.create(name: "Test 2", email: "test2@test.com", password: "123123123")
    post authenticate_url, params: {email: "test@test.com", password: "123123123"}, as: :json
    @authorization = JSON.parse(response.body)["auth_token"]
    post authenticate_url, params: {email: "test2@test.com", password: "123123123"}, as: :json
    @authorization2 = JSON.parse(response.body)["auth_token"]
  end

  test "should get index" do
    get games_url, headers: {Authorization: @authorization}, as: :json
    assert_response :success
  end

  test "should create game" do
    assert_difference('Game.count') do
      post games_url, headers: {Authorization: @authorization}, as: :json
    end

    assert_response 204
  end

  test "should show game" do
    game = Game.create(users: [@user])
    get game_url(game), headers: {Authorization: @authorization}, as: :json
    assert_response :success
  end

  test "should join game" do
    game = Game.create(users: [@user])
    put game_join_url(game), headers: {Authorization: @authorization2}, as: :json
    assert_response 204
    assert_equal game.reload.users.size, 2
  end

  test "should move in game" do
    game = Game.create(users: User.all.to_a)
    put game_move_url(game), headers: {Authorization: @authorization}, params: {move: [0,0]}, as: :json
    assert_response 204
    assert_equal game.reload.history.size, 2
  end

  test "should destroy game" do
    assert_difference('Game.count', 0) do
      game = Game.create(users: [@user])
      delete game_url(game), headers: {Authorization: @authorization}, as: :json
    end

    assert_response 204
  end
end
