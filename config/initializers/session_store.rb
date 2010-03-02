# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_skip-log-analyzer_session',
  :secret      => '330c8d01b83e672562bd55a0f93f2cf0bcea28c5a03e7475de93f90f6bca23f620a8d616f98eb5ad237d715234341ce11511405bb1946a229fdb643e1fd963af'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
