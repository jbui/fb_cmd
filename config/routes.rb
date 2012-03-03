FbCmd::Application.routes.draw do
  root :to => 'home#index'

  # routes for omniauth
  match '/auth/facebook/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'

end
