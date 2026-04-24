# Phase 1 — Core Domain + Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the User, Property, and Room models with full CRUD REST API endpoints and JWT-based authentication, establishing the core domain that all subsequent phases depend on.

**Architecture:** Rails models for User (bcrypt password hashing via `has_secure_password`), Property (owned by a User), and Room (belonging to a Property). JWT tokens issued on login are verified via an `Authenticatable` concern included in `BaseController`. All authenticated routes require `Authorization: Bearer <token>`. Serializers use `active_model_serializers` 0.10 with the default Attributes adapter (flat JSON, no root key).

**Tech Stack:** Ruby 3.2.2 · Rails 7.2 · PostgreSQL 16 · jwt gem · bcrypt (has_secure_password) · RSpec 6.1 · FactoryBot · shoulda-matchers · active_model_serializers 0.10

---

## Setup

```bash
git checkout main && git pull
git checkout feature/phase1-core-domain
```

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `db/migrate/TIMESTAMP_create_users.rb` | Create | users table with bcrypt column |
| `db/migrate/TIMESTAMP_create_properties.rb` | Create | properties table with user FK |
| `db/migrate/TIMESTAMP_create_rooms.rb` | Create | rooms table with property FK |
| `app/models/user.rb` | Create | Validations, has_secure_password, has_many :properties |
| `app/models/property.rb` | Create | Validations, belongs_to :user, has_many :rooms |
| `app/models/room.rb` | Create | Validations, belongs_to :property |
| `spec/factories/users.rb` | Create | FactoryBot user factory |
| `spec/factories/properties.rb` | Create | FactoryBot property factory |
| `spec/factories/rooms.rb` | Create | FactoryBot room factory |
| `spec/models/user_spec.rb` | Create | User validations + associations |
| `spec/models/property_spec.rb` | Create | Property validations + associations |
| `spec/models/room_spec.rb` | Create | Room validations + associations |
| `app/services/json_web_token.rb` | Create | JWT encode/decode |
| `spec/services/json_web_token_spec.rb` | Create | JWT encode/decode tests |
| `app/controllers/concerns/authenticatable.rb` | Create | `authenticate_user!` before_action |
| `app/controllers/api/v1/base_controller.rb` | Modify | include Authenticatable |
| `app/serializers/user_serializer.rb` | Create | User JSON attributes |
| `app/serializers/property_serializer.rb` | Create | Property JSON attributes |
| `app/serializers/room_serializer.rb` | Create | Room JSON attributes |
| `app/controllers/api/v1/sessions_controller.rb` | Create | POST /sessions, DELETE /sessions/:id |
| `app/controllers/api/v1/users_controller.rb` | Create | User CRUD |
| `app/controllers/api/v1/properties_controller.rb` | Create | Property CRUD |
| `app/controllers/api/v1/rooms_controller.rb` | Create | Room CRUD |
| `spec/requests/api/v1/sessions_spec.rb` | Create | Session request specs |
| `spec/requests/api/v1/users_spec.rb` | Create | User request specs |
| `spec/requests/api/v1/properties_spec.rb` | Create | Property request specs |
| `spec/requests/api/v1/rooms_spec.rb` | Create | Room request specs |

---

## Task 1: User Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_users.rb`
- Create: `app/models/user.rb`
- Create: `spec/factories/users.rb`
- Create: `spec/models/user_spec.rb`

- [ ] **Step 1: Generate migration**

```bash
bundle exec rails generate migration CreateUsers
```

This creates `db/migrate/TIMESTAMP_create_users.rb`. Edit that file to match exactly:

```ruby
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email,           null: false
      t.string :password_digest, null: false
      t.string :first_name,      null: false
      t.string :last_name,       null: false
      t.string :role,            null: false, default: 'tenant'
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

- [ ] **Step 2: Run migrations**

```bash
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:migrate
```

Expected: `== CreateUsers: migrated`

- [ ] **Step 3: Create factory**

Create `spec/factories/users.rb`:

```ruby
FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    role { 'landlord' }

    trait :tenant do
      role { 'tenant' }
    end
  end
end
```

- [ ] **Step 4: Write failing model spec**

Create `spec/models/user_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_inclusion_of(:role).in_array(%w[landlord tenant]) }
    it { should have_secure_password }
  end

  describe 'associations' do
    it { should have_many(:properties).dependent(:destroy) }
  end

  describe 'email normalization' do
    it 'downcases email before saving' do
      user = create(:user, email: 'TEST@EXAMPLE.COM')
      expect(user.reload.email).to eq('test@example.com')
    end
  end
end
```

- [ ] **Step 5: Run spec — expect failure**

```bash
bundle exec rspec spec/models/user_spec.rb
```

Expected: `uninitialized constant User` or validation failures.

- [ ] **Step 6: Implement User model**

Create `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  has_secure_password

  has_many :properties, dependent: :destroy

  ROLES = %w[landlord tenant].freeze

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: ROLES }

  before_save { self.email = email.downcase }
end
```

- [ ] **Step 7: Run spec — expect all green**

```bash
bundle exec rspec spec/models/user_spec.rb
```

Expected: all examples pass.

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*create_users* app/models/user.rb \
        spec/factories/users.rb spec/models/user_spec.rb
git commit -m "feat: add User model with bcrypt, validations, email normalization"
```

---

## Task 2: Property Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_properties.rb`
- Create: `app/models/property.rb`
- Create: `spec/factories/properties.rb`
- Create: `spec/models/property_spec.rb`

- [ ] **Step 1: Generate migration**

```bash
bundle exec rails generate migration CreateProperties
```

Edit the generated file:

```ruby
class CreateProperties < ActiveRecord::Migration[7.2]
  def change
    create_table :properties do |t|
      t.string     :name,    null: false
      t.string     :address, null: false
      t.references :user,    null: false, foreign_key: true
      t.timestamps
    end
  end
end
```

- [ ] **Step 2: Run migrations**

```bash
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:migrate
```

- [ ] **Step 3: Create factory**

Create `spec/factories/properties.rb`:

```ruby
FactoryBot.define do
  factory :property do
    name    { Faker::Address.community }
    address { Faker::Address.full_address }
    association :user
  end
end
```

- [ ] **Step 4: Write failing model spec**

Create `spec/models/property_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Property, type: :model do
  subject { build(:property) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:address) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:rooms).dependent(:destroy) }
  end
end
```

- [ ] **Step 5: Run spec — expect failure**

```bash
bundle exec rspec spec/models/property_spec.rb
```

- [ ] **Step 6: Implement Property model**

Create `app/models/property.rb`:

```ruby
class Property < ApplicationRecord
  belongs_to :user
  has_many :rooms, dependent: :destroy

  validates :name, :address, presence: true
end
```

- [ ] **Step 7: Run spec — expect all green**

```bash
bundle exec rspec spec/models/property_spec.rb
```

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*create_properties* app/models/property.rb \
        spec/factories/properties.rb spec/models/property_spec.rb
git commit -m "feat: add Property model"
```

---

## Task 3: Room Model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_rooms.rb`
- Create: `app/models/room.rb`
- Create: `spec/factories/rooms.rb`
- Create: `spec/models/room_spec.rb`

- [ ] **Step 1: Generate migration**

```bash
bundle exec rails generate migration CreateRooms
```

Edit the generated file:

```ruby
class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.string     :name,         null: false
      t.decimal    :surface_area, precision: 8,  scale: 2
      t.decimal    :rent,         precision: 10, scale: 2, null: false
      t.decimal    :charges,      precision: 10, scale: 2, null: false, default: 0
      t.references :property,     null: false, foreign_key: true
      t.timestamps
    end
  end
end
```

- [ ] **Step 2: Run migrations**

```bash
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:migrate
```

- [ ] **Step 3: Create factory**

Create `spec/factories/rooms.rb`:

```ruby
FactoryBot.define do
  factory :room do
    name         { "Room #{Faker::Number.number(digits: 2)}" }
    surface_area { rand(10.0..80.0).round(2) }
    rent         { rand(300.0..2000.0).round(2) }
    charges      { rand(0.0..200.0).round(2) }
    association :property
  end
end
```

- [ ] **Step 4: Write failing model spec**

Create `spec/models/room_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Room, type: :model do
  subject { build(:room) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:rent) }
    it { should validate_numericality_of(:rent).is_greater_than(0) }
    it { should validate_numericality_of(:charges).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:surface_area).is_greater_than(0).allow_nil }
  end

  describe 'associations' do
    it { should belong_to(:property) }
  end
end
```

- [ ] **Step 5: Run spec — expect failure**

```bash
bundle exec rspec spec/models/room_spec.rb
```

- [ ] **Step 6: Implement Room model**

Create `app/models/room.rb`:

```ruby
class Room < ApplicationRecord
  belongs_to :property

  validates :name, presence: true
  validates :rent, presence: true, numericality: { greater_than: 0 }
  validates :charges, numericality: { greater_than_or_equal_to: 0 }
  validates :surface_area, numericality: { greater_than: 0 }, allow_nil: true
end
```

- [ ] **Step 7: Run spec — expect all green**

```bash
bundle exec rspec spec/models/room_spec.rb
```

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*create_rooms* app/models/room.rb \
        spec/factories/rooms.rb spec/models/room_spec.rb
git commit -m "feat: add Room model"
```

---

## Task 4: JWT Service

**Files:**
- Create: `app/services/json_web_token.rb`
- Create: `spec/services/json_web_token_spec.rb`

- [ ] **Step 1: Write failing spec**

```bash
mkdir -p spec/services
```

Create `spec/services/json_web_token_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 42 } }

  describe '.encode' do
    it 'returns a three-part JWT string' do
      token = JsonWebToken.encode(payload)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'embeds the user_id in the payload' do
      token = JsonWebToken.encode(payload)
      decoded = JsonWebToken.decode(token)
      expect(decoded[:user_id]).to eq(42)
    end
  end

  describe '.decode' do
    it 'decodes a valid token' do
      token = JsonWebToken.encode(payload)
      decoded = JsonWebToken.decode(token)
      expect(decoded[:user_id]).to eq(payload[:user_id])
    end

    it 'raises JWT::DecodeError for a tampered token' do
      expect { JsonWebToken.decode('bad.token.here') }.to raise_error(JWT::DecodeError)
    end

    it 'raises JWT::DecodeError for an expired token' do
      expired = JsonWebToken.encode(payload, 1.second.ago)
      expect { JsonWebToken.decode(expired) }.to raise_error(JWT::DecodeError)
    end
  end
end
```

- [ ] **Step 2: Run spec — expect failure**

```bash
bundle exec rspec spec/services/json_web_token_spec.rb
```

Expected: `uninitialized constant JsonWebToken`

- [ ] **Step 3: Implement JWT service**

Create `app/services/json_web_token.rb`:

```ruby
class JsonWebToken
  SECRET = ENV.fetch('JWT_SECRET', 'fallback_secret_development_only')
  EXPIRY = 24.hours

  def self.encode(payload, exp = EXPIRY.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: 'HS256').first
    HashWithIndifferentAccess.new(decoded)
  end
end
```

- [ ] **Step 4: Run spec — expect all green**

```bash
bundle exec rspec spec/services/json_web_token_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/services/json_web_token.rb spec/services/json_web_token_spec.rb
git commit -m "feat: add JsonWebToken service (encode/decode HS256)"
```

---

## Task 5: Authenticatable Concern + Serializers

**Files:**
- Create: `app/controllers/concerns/authenticatable.rb`
- Modify: `app/controllers/api/v1/base_controller.rb`
- Create: `app/serializers/user_serializer.rb`
- Create: `app/serializers/property_serializer.rb`
- Create: `app/serializers/room_serializer.rb`

- [ ] **Step 1: Create Authenticatable concern**

Create `app/controllers/concerns/authenticatable.rb`:

```ruby
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    header = request.headers['Authorization']
    token  = header&.split(' ')&.last
    raise JWT::DecodeError, 'Missing token' if token.nil?

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
```

- [ ] **Step 2: Update BaseController to include Authenticatable**

Replace the full content of `app/controllers/api/v1/base_controller.rb`:

```ruby
module Api
  module V1
    class BaseController < ApplicationController
      include Authenticatable

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def not_found
        render json: { error: 'Not found' }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
```

- [ ] **Step 3: Create serializers**

Create `app/serializers/user_serializer.rb`:

```ruby
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :first_name, :last_name, :role, :created_at
end
```

Create `app/serializers/property_serializer.rb`:

```ruby
class PropertySerializer < ActiveModel::Serializer
  attributes :id, :name, :address, :user_id, :created_at
end
```

Create `app/serializers/room_serializer.rb`:

```ruby
class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :surface_area, :rent, :charges, :property_id, :created_at
end
```

- [ ] **Step 4: Verify existing specs still pass**

```bash
bundle exec rspec spec/models spec/services
```

Expected: all green (no regressions).

- [ ] **Step 5: Commit**

```bash
git add app/controllers/concerns/authenticatable.rb \
        app/controllers/api/v1/base_controller.rb \
        app/serializers/
git commit -m "feat: add Authenticatable concern + AMS serializers"
```

---

## Task 6: Sessions Controller

**Files:**
- Create: `app/controllers/api/v1/sessions_controller.rb`
- Create: `spec/requests/api/v1/sessions_spec.rb`

Session JSON response shape:
```json
{ "token": "eyJ...", "user": { "id": 1, "email": "...", "first_name": "...", "last_name": "...", "role": "landlord", "created_at": "..." } }
```

- [ ] **Step 1: Write failing request spec**

```bash
mkdir -p spec/requests/api/v1
```

Create `spec/requests/api/v1/sessions_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let(:user) { create(:user, email: 'landlord@example.com', password: 'secret123') }

  describe 'POST /api/v1/sessions' do
    context 'with valid credentials' do
      it 'returns 200 with token and user' do
        post '/api/v1/sessions', params: { email: user.email, password: 'secret123' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('landlord@example.com')
        expect(json['user']).not_to have_key('password_digest')
      end
    end

    context 'with wrong password' do
      it 'returns 401' do
        post '/api/v1/sessions', params: { email: user.email, password: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end

    context 'with unknown email' do
      it 'returns 401' do
        post '/api/v1/sessions', params: { email: 'nobody@example.com', password: 'any' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/sessions/:id' do
    context 'when authenticated' do
      it 'returns 200 with message' do
        delete '/api/v1/sessions/1', headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to be_present
      end
    end

    context 'without token' do
      it 'returns 401' do
        delete '/api/v1/sessions/1'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

- [ ] **Step 2: Run spec — expect failure**

```bash
bundle exec rspec spec/requests/api/v1/sessions_spec.rb
```

Expected: routing error (controller not defined yet).

- [ ] **Step 3: Implement SessionsController**

Create `app/controllers/api/v1/sessions_controller.rb`:

```ruby
module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = User.find_by(email: params[:email]&.downcase)

        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user).attributes }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def destroy
        # JWT is stateless — client must discard the token
        render json: { message: 'Signed out successfully' }, status: :ok
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect all green**

```bash
bundle exec rspec spec/requests/api/v1/sessions_spec.rb
```

Expected: 5 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/sessions_controller.rb \
        spec/requests/api/v1/sessions_spec.rb
git commit -m "feat: add SessionsController (JWT login/logout)"
```

---

## Task 7: Users Controller

**Files:**
- Create: `app/controllers/api/v1/users_controller.rb`
- Create: `spec/requests/api/v1/users_spec.rb`

Authorization rules:
- `POST /users` — public (registration)
- `GET /users` — any authenticated user (returns all users)
- `GET /users/:id` — any authenticated user (show any profile)
- `PATCH /users/:id` — own account only → 403 otherwise
- `DELETE /users/:id` — own account only → 403 otherwise

- [ ] **Step 1: Write failing request spec**

Create `spec/requests/api/v1/users_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST /api/v1/users (registration)' do
    let(:valid_params) do
      { email: 'new@example.com', password: 'password123',
        first_name: 'Jane', last_name: 'Doe', role: 'landlord' }
    end

    context 'with valid params' do
      it 'creates a user and returns token + user' do
        post '/api/v1/users', params: valid_params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['user']['email']).to eq('new@example.com')
        expect(json['user']).not_to have_key('password_digest')
        expect(User.count).to eq(1)
      end
    end

    context 'with duplicate email' do
      it 'returns 422 with errors array' do
        create(:user, email: 'new@example.com')
        post '/api/v1/users', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to be_a(Array)
      end
    end

    context 'with missing password' do
      it 'returns 422' do
        post '/api/v1/users', params: { email: 'x@x.com', first_name: 'A', last_name: 'B' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /api/v1/users' do
    it 'returns all users for authenticated user' do
      user && other_user
      get '/api/v1/users', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(2)
    end

    it 'returns 401 without token' do
      get '/api/v1/users'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'returns the user' do
      get "/api/v1/users/#{user.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
      expect(json['email']).to eq(user.email)
    end

    it 'returns 404 for non-existent user' do
      get '/api/v1/users/99999', headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    context 'when updating own account' do
      it 'updates and returns updated user' do
        patch "/api/v1/users/#{user.id}",
              params: { first_name: 'Updated' },
              headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['first_name']).to eq('Updated')
      end
    end

    context 'when updating another user' do
      it 'returns 403 Forbidden' do
        patch "/api/v1/users/#{other_user.id}",
              params: { first_name: 'Hacked' },
              headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
        expect(other_user.reload.first_name).not_to eq('Hacked')
      end
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    context 'when deleting own account' do
      it 'deletes the account and returns ok' do
        delete "/api/v1/users/#{user.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(User.exists?(user.id)).to be false
      end
    end

    context 'when deleting another user' do
      it 'returns 403 Forbidden' do
        delete "/api/v1/users/#{other_user.id}", headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
        expect(User.exists?(other_user.id)).to be true
      end
    end
  end
end
```

- [ ] **Step 2: Run spec — expect failure**

```bash
bundle exec rspec spec/requests/api/v1/users_spec.rb
```

- [ ] **Step 3: Implement UsersController**

Create `app/controllers/api/v1/users_controller.rb`:

```ruby
module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]
      before_action :set_user, only: [:show, :update, :destroy]

      def create
        user = User.new(user_params)
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user).attributes }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index
        render json: User.all.order(:created_at), each_serializer: UserSerializer
      end

      def show
        render json: @user, serializer: UserSerializer
      end

      def update
        authorize_self!
        return unless performed?

        if @user.update(user_params)
          render json: @user, serializer: UserSerializer
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize_self!
        return unless performed?

        @user.destroy
        render json: { message: 'Account deleted' }, status: :ok
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def authorize_self!
        return if @user == current_user

        render json: { error: 'Forbidden' }, status: :forbidden
      end

      def user_params
        params.permit(:email, :password, :first_name, :last_name, :role)
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect all green**

```bash
bundle exec rspec spec/requests/api/v1/users_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/users_controller.rb \
        spec/requests/api/v1/users_spec.rb
git commit -m "feat: add UsersController (register, CRUD, self-only mutation)"
```

---

## Task 8: Properties Controller

**Files:**
- Create: `app/controllers/api/v1/properties_controller.rb`
- Create: `spec/requests/api/v1/properties_spec.rb`

Authorization: all operations scoped to `current_user.properties` — attempting to access another user's property returns 404 (not 403, to avoid leaking existence).

- [ ] **Step 1: Write failing request spec**

Create `spec/requests/api/v1/properties_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Properties', type: :request do
  let(:user)           { create(:user) }
  let(:other_user)     { create(:user) }
  let(:property)       { create(:property, user: user) }
  let(:other_property) { create(:property, user: other_user) }

  describe 'GET /api/v1/properties' do
    it 'returns only current user properties' do
      property && other_property
      get '/api/v1/properties', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |p| p['id'] }
      expect(ids).to include(property.id)
      expect(ids).not_to include(other_property.id)
    end

    it 'returns 401 without token' do
      get '/api/v1/properties'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/properties/:id' do
    it 'returns own property' do
      get "/api/v1/properties/#{property.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(property.id)
      expect(json['name']).to eq(property.name)
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns 404 for another user property' do
      get "/api/v1/properties/#{other_property.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/properties' do
    it 'creates a property owned by current user' do
      post '/api/v1/properties',
           params: { property: { name: 'Mon Appartement', address: '1 Rue de Rivoli, Paris' } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Mon Appartement')
      expect(json['user_id']).to eq(user.id)
    end

    it 'returns 422 when name is missing' do
      post '/api/v1/properties',
           params: { property: { address: '1 Rue de Rivoli, Paris' } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_a(Array)
    end
  end

  describe 'PATCH /api/v1/properties/:id' do
    it 'updates own property' do
      patch "/api/v1/properties/#{property.id}",
            params: { property: { name: 'Renamed' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Renamed')
    end

    it 'returns 404 for another user property' do
      patch "/api/v1/properties/#{other_property.id}",
            params: { property: { name: 'Hijacked' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/properties/:id' do
    it 'destroys own property and returns ok' do
      delete "/api/v1/properties/#{property.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(Property.exists?(property.id)).to be false
    end

    it 'returns 404 for another user property' do
      delete "/api/v1/properties/#{other_property.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/properties/:id/documents' do
    it 'returns empty documents array (Phase 3 stub)' do
      get "/api/v1/properties/#{property.id}/documents", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['documents']).to eq([])
    end
  end
end
```

- [ ] **Step 2: Run spec — expect failure**

```bash
bundle exec rspec spec/requests/api/v1/properties_spec.rb
```

- [ ] **Step 3: Implement PropertiesController**

Create `app/controllers/api/v1/properties_controller.rb`:

```ruby
module Api
  module V1
    class PropertiesController < BaseController
      before_action :set_property, only: [:show, :update, :destroy, :documents]

      def index
        render json: current_user.properties.order(:created_at), each_serializer: PropertySerializer
      end

      def show
        render json: @property, serializer: PropertySerializer
      end

      def create
        property = current_user.properties.build(property_params)
        if property.save
          render json: property, serializer: PropertySerializer, status: :created
        else
          render json: { errors: property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @property.update(property_params)
          render json: @property, serializer: PropertySerializer
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @property.destroy
        render json: { message: 'Property deleted' }, status: :ok
      end

      def documents
        # Phase 3: returns signed S3 URLs — stubbed for now
        render json: { documents: [] }
      end

      private

      def set_property
        # Scoped to current_user — raises RecordNotFound (→ 404) for other users' properties
        @property = current_user.properties.find(params[:id])
      end

      def property_params
        params.require(:property).permit(:name, :address)
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect all green**

```bash
bundle exec rspec spec/requests/api/v1/properties_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/properties_controller.rb \
        spec/requests/api/v1/properties_spec.rb
git commit -m "feat: add PropertiesController with owner-scoped authorization"
```

---

## Task 9: Rooms Controller

**Files:**
- Create: `app/controllers/api/v1/rooms_controller.rb`
- Create: `spec/requests/api/v1/rooms_spec.rb`

Routes: `resources :rooms, only: [:create, :update, :destroy, :index]` — rooms are **not** nested under properties in the URL. `property_id` is passed as a param in the request body (create) or as a query param (index filter). Authorization is enforced by scoping through `current_user.properties`.

- [ ] **Step 1: Write failing request spec**

Create `spec/requests/api/v1/rooms_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Rooms', type: :request do
  let(:user)           { create(:user) }
  let(:other_user)     { create(:user) }
  let(:property)       { create(:property, user: user) }
  let(:other_property) { create(:property, user: other_user) }
  let(:room)           { create(:room, property: property) }
  let(:other_room)     { create(:room, property: other_property) }

  describe 'GET /api/v1/rooms' do
    it 'returns only rooms from current user properties' do
      room && other_room
      get '/api/v1/rooms', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |r| r['id'] }
      expect(ids).to include(room.id)
      expect(ids).not_to include(other_room.id)
    end

    it 'filters by property_id when provided' do
      other_property_of_user = create(:property, user: user)
      room2 = create(:room, property: other_property_of_user)
      room

      get '/api/v1/rooms', params: { property_id: property.id }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |r| r['id'] }
      expect(ids).to include(room.id)
      expect(ids).not_to include(room2.id)
    end

    it 'returns 404 when filtering by another user property_id' do
      get '/api/v1/rooms', params: { property_id: other_property.id }, headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/rooms' do
    let(:valid_params) do
      { room: { name: 'Studio', rent: '650.00', charges: '50.00',
                surface_area: '25.00', property_id: property.id } }
    end

    it 'creates a room in own property' do
      post '/api/v1/rooms', params: valid_params, headers: auth_headers(user)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Studio')
      expect(json['property_id']).to eq(property.id)
      expect(json['rent'].to_f).to eq(650.0)
    end

    it 'returns 404 when property belongs to another user' do
      post '/api/v1/rooms',
           params: { room: { name: 'X', rent: '500', property_id: other_property.id } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 422 when rent is missing' do
      post '/api/v1/rooms',
           params: { room: { name: 'X', property_id: property.id } },
           headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/rooms/:id' do
    it 'updates own room' do
      patch "/api/v1/rooms/#{room.id}",
            params: { room: { rent: '750.00' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['rent'].to_f).to eq(750.0)
    end

    it 'returns 404 for another user room' do
      patch "/api/v1/rooms/#{other_room.id}",
            params: { room: { rent: '1.00' } },
            headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/rooms/:id' do
    it 'destroys own room' do
      delete "/api/v1/rooms/#{room.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(Room.exists?(room.id)).to be false
    end

    it 'returns 404 for another user room' do
      delete "/api/v1/rooms/#{other_room.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end
end
```

- [ ] **Step 2: Run spec — expect failure**

```bash
bundle exec rspec spec/requests/api/v1/rooms_spec.rb
```

- [ ] **Step 3: Implement RoomsController**

Create `app/controllers/api/v1/rooms_controller.rb`:

```ruby
module Api
  module V1
    class RoomsController < BaseController
      before_action :set_room, only: [:update, :destroy]

      def index
        rooms = if params[:property_id]
                  current_user.properties.find(params[:property_id]).rooms
                else
                  Room.joins(:property).where(properties: { user_id: current_user.id })
                end
        render json: rooms.order(:created_at), each_serializer: RoomSerializer
      end

      def create
        property = current_user.properties.find(room_params[:property_id])
        room = property.rooms.build(room_params.except('property_id'))
        if room.save
          render json: room, serializer: RoomSerializer, status: :created
        else
          render json: { errors: room.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @room.update(room_params.except('property_id'))
          render json: @room, serializer: RoomSerializer
        else
          render json: { errors: @room.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @room.destroy
        render json: { message: 'Room deleted' }, status: :ok
      end

      private

      def set_room
        @room = Room.joins(:property)
                    .where(properties: { user_id: current_user.id })
                    .find(params[:id])
      end

      def room_params
        params.require(:room).permit(:name, :surface_area, :rent, :charges, :property_id)
      end
    end
  end
end
```

- [ ] **Step 4: Run spec — expect all green**

```bash
bundle exec rspec spec/requests/api/v1/rooms_spec.rb
```

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/rooms_controller.rb \
        spec/requests/api/v1/rooms_spec.rb
git commit -m "feat: add RoomsController"
```

---

## Task 10: Full Suite + PR

- [ ] **Step 1: Run full test suite**

```bash
bundle exec rspec
```

Expected:
```
Finished in X seconds
XX examples, 0 failures
```

- [ ] **Step 2: Run RuboCop on app/**

```bash
bundle exec rubocop app/
```

Expected: `no offenses detected`

If there are offenses, run `bundle exec rubocop --autocorrect app/` for auto-fixable ones, then fix the rest manually.

- [ ] **Step 3: Commit any style fixes**

```bash
git add app/
git commit -m "style: fix RuboCop offenses"
```

(Skip this step if rubocop was clean.)

- [ ] **Step 4: Push and open PR**

```bash
git push origin feature/phase1-core-domain
gh pr create \
  --title "feat: Phase 1 — Core Domain + Auth" \
  --body "Adds User/Property/Room models with full CRUD REST API and JWT authentication. All endpoints require Bearer token except POST /sessions and POST /users." \
  --base main
```

---

## Phase 1 Success Criteria

- `bundle exec rspec` → all green
- `bundle exec rubocop app/` → 0 offenses
- `POST /api/v1/sessions` with valid credentials → `{ token: "...", user: { ... } }`
- `GET /api/v1/properties` without token → `401 Unauthorized`
- `GET /api/v1/properties` with valid token → only current user's properties
- `POST /api/v1/rooms` with another user's `property_id` → `404 Not Found`
- `PATCH /api/v1/users/:other_id` → `403 Forbidden`

**Next:** Phase 2 — Lease Applications (LeaseApplication model, state machine: pending → approved/rejected, payment tracking)
