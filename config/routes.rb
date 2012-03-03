FbCmd::Application.routes.draw do
  root :to => 'home#index'

  # routes for omniauth
  match '/auth/facebook/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'


  # routes for input
  match '/api' => 'recipes#parse'
  match '/get_video/:id' => 'videos#show'

  # profile
  match '/profile' => 'home#profile'

end
