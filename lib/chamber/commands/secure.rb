require 'chamber/commands/base'

module  Chamber
module  Commands
class   Secure < Chamber::Commands::Base
  include Chamber::Commands::Securable

  def initialize(options = {})
    super(options.merge(namespaces: ['*']))
  end

  def call
    disable_warnings do
      possibly_encrypted_environment_variables.each do |key, value|
        next if value.match %r{\A[A-Za-z0-9\+\/]{342}==\z}

        if dry_run
          shell.say_status 'encrypt', key, :blue
        else
          shell.say_status 'encrypt', key, :green
        end
      end
    end

    chamber.secure unless dry_run
  end

  private

  def disable_warnings
    $stderr = ::File.open('/dev/null', 'w')

    yield

    $stderr = STDERR
  end

  # FIXME: This is a super hacky workaround, pending hearing from upstream
  # about how to fix issue #22.
  def possibly_encrypted_environment_variables
    env = SystemEnvironment.extract_from(secured_settings.send(:raw_data))

    env.map do |key, value|
      [key.sub(/_SECURE_/, ''), value]
    end
  end
end
end
end
