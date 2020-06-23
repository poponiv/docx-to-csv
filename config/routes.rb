Rails.application.routes.draw do
  # get 'input_docs/index'
  # get 'input_docs/new'
  # get 'input_docs/create'
  # get 'input_docs/destroy'
  resources :input_docs, only: [:index, :new, :create, :destroy]
  resources :amazon_documents, only: [:index, :new, :create, :destroy]
  root "home#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
