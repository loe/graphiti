set :application, "graphiti"
set :deploy_to, lambda { "/opt/app/#{application}-#{env}" }
set :deploy_via, :remote_cache
set :scm, :git
set :repository, "git@github.com:paperlesspost/graphiti.git"
set :user, "paperless"
set :use_sudo, false
set :normalize_asset_timestamps, false

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "sudo status graphiti | grep -q start && sudo restart graphiti || sudo start graphiti"
  end

  task :stop, :roles => :app, :except => { :no_release => true } do
    run "sudo status graphiti | grep -q start && sudo stop graphiti || 0"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo status graphiti | grep -q start && sudo restart graphiti || sudo start graphiti"
  end
end

task :production do
  set :env, 'production'
  server 'production-graphiti01.pp.prod', :web, :app, :db, :primary => true,
end

namespace :graphiti do
  task :link_configs do
    run %{cd #{release_path} &&
          ln -nfs #{shared_path}/config/settings.yml #{release_path}/config/settings.yml &&
          ln -nfs #{shared_path}/config/amazon_s3.yml #{release_path}/config/amazon_s3.yml &&
          rm #{release_path}/config/unicorn.rb && ln -nfs #{shared_path}/config/unicorn.rb #{release_path}/config/unicorn.rb
        }
  end

  task :compress do
    run "cd #{release_path} && bundle exec jim compress"
  end
end

namespace :bundler do
  desc "Automatically installed your bundled gems if a Gemfile exists"
  task :install_gems, :roles => :web do
    run %{if [ -f #{release_path}/Gemfile ]; then cd #{release_path} &&
      mkdir -p #{release_path}/vendor &&
      ln -nfs #{shared_path}/bundle #{release_path}/vendor/bundle &&
      bundle install --without test development --deployment; fi
    }
  end
end

after "deploy:update_code", "graphiti:link_configs"
after "deploy:update_code", "bundler:install_gems"
after "deploy:update_code", "graphiti:compress"
