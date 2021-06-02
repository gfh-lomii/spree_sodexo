Spree::Core::Engine.routes.draw do
  post '/sodexo', to: "sodexo#pay", as: :sodexo
  get '/sodexo/successg/:payment', to: redirect('/sodexo/success/%{payment}'), as: :sodexo_successg
  get '/sodexo/success/:payment', to: "sodexo#success", as: :sodexo_success
  get '/sodexo/cancel/:payment', to: "sodexo#cancel", as: :sodexo_cancel
  post '/sodexo/notify', to: 'sodexo#notify'
  post '/sodexo/failure', to: 'sodexo#failure'
end
