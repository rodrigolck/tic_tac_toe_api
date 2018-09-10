Rails.application.routes.draw do
  resources :games, only: [:index, :show, :create, :destroy] do
    put :move
    put :join
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post 'authenticate', to: 'authentication#authenticate'
end
