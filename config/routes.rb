Rails.application.routes.draw do
  root 'pages#index'
  get 'pages/search'
#  post 'pages/search', to: 'pages#update', as: 'pages_update'
end
