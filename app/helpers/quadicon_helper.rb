module QuadiconHelper
  QUADRANTS = %i(top_left top_right bottom_left bottom_right middle).freeze
  POLICY_SHIELD = {
    :fonticon => 'fa fa-shield',
    :color    => '#f5c12e',
    :tooltip  => _('This object has policies assigned.')
  }.freeze

  MACHINE_STATE_QUADRANT = {
    'archived'                  => {:text => 'A', :background => '#336699'},
    'orphaned'                  => {:text => 'O', :background => '#336699'},
    'retired'                   => {:text => 'R', :background => '#336699'},
    'unknown'                   => {:fonticon => 'pficon pficon-unknown', :background => '#336699'},
    'preparing_for_maintenance' => {:fonticon => 'pficon pficon-maintenance', :background => '#336699'},
    'maintenance'               => {:fonticon => 'pficon pficon-maintenance', :background => '#336699'},
    'disconnected'              => {:fonticon => 'pficon pficon-unplugged', :background => '#336699'},
    'non_operational'           => {:fonticon => 'fa fa-exclamation', :background => '#336699'},
    'not_responding'            => {:fonticon => 'fa fa-exclamation', :background => '#336699'},
    'install_failed'            => {:fonticon => 'fa fa-exclamation', :background => '#336699'},
    'suspended'                 => {:fonticon => 'pficon pficon-asleep', :background => '#FF9900'},
    'standby'                   => {:fonticon => 'pficon pficon-asleep', :background => '#FF9900'},
    'paused'                    => {:fonticon => 'pficon pficon-asleep', :background => '#FF9900'},
    'disconnecting'             => {:fonticon => 'pficon pficon-unplugged', :background => '#FF9900'},
    'image_locked'              => {:fonticon => 'pficon pficon-locked', :background => '#FF9900'},
    'migrating'                 => {:fonticon => 'pficon pficon-migration', :background => '#FF9900'},
    'shelved'                   => {:fonticon => 'pficon pficon-pending', :background => '#FF9900'},
    'shelved_offloaded'         => {:fonticon => 'pficon pficon-pending', :background => '#FF9900'},
    'reboot_in_progress'        => {:fonticon => 'pficon pficon-on', :background => '#FF9900'},
    'wait_for_launch'           => {:fonticon => 'pficon pficon-asleep', :background => '#FF9900'},
    'on'                        => {:fonticon => 'pficon pficon-on', :background => '#3F9C35'},
    'never'                     => {:fonticon => 'pficon pficon-off', :background => '#CC0000'},
    'terminated'                => {:fonticon => 'pficon pficon-off', :background => '#CC0000'},
    'off'                       => {:fonticon => 'pficon pficon-off', :background => '#CC0000'},
    'template'                  => {:fonticon => 'pficon pficon-template', :background => '#336699'},
  }.freeze

  def self.status_img(status)
    case status
    when "Invalid" then "100/x.png"
    when "Valid"   then "100/checkmark.png"
    when "None"    then "100/unknown.png"
    else                "100/exclamationpoint.png"
    end
  end

  def self.compliance_img(status)
    case status
    when true  then '100/check.png'
    when 'N/A' then '100/na.png'
    else            '100/x.png'
    end
  end

  def self.os_icon(name)
    name == "unknown" ? { :fonticon => 'pficon pficon-unknown' } : {:fileicon => "svg/os-#{ERB::Util.h(name)}.svg" }
  end

  def self.machine_state(state_str)
    MACHINE_STATE_QUADRANT[state_str.try(:downcase)] || {}
  end

  # Change the bottom-right quadrant of the quadicon with the policy simulation result
  def policy_sim(quad, result)
    if quad.try(:[], :bottom_right)
      img = case result
            when true  then '100/check.png'
            when 'N/A' then '100/na.png'
            else            '100/x.png'
            end

      quad[:bottom_right] = {
        :fileicon => img,
        :tooltip  => result
      }
    end
    quad
  end

  def quadrant_output(quadrant)
    # Call asset_path on the fileicon value
    quadrant[:fileicon] = ActionController::Base.helpers.image_path(quadrant[:fileicon]) if quadrant.try(:[], :fileicon)
    # Convert all numbers to string
    quadrant[:text] = quadrant[:text].to_s if quadrant.try(:[], :text).kind_of?(Numeric)

    quadrant
  end

  def quadicon_output(quadicon)
    if (quadicon.keys & QUADRANTS).any?
      QUADRANTS.each do |part|
        quadicon[part] = quadrant_output(quadicon[part])
      end
    else
      quadicon = quadrant_output(quadicon)
    end

    quadicon
  end

  def quadicon_hash(item)
    settings_key = item.class.try(:decorate).try(:to_s).try(:chomp, 'Decorator').try(:demodulize).try(:underscore).try(:to_sym)
    # Quadicons should be displayed when explicitly set or when the user is on the policy simulation screen
    quad_method = if settings(:quadicons, settings_key) || !!@policy_sim
                    :quadicon
                  else
                    :single_quad
                  end
    quad_icon = item.try(:decorate).try(quad_method)
    # Fall back to a single quad if a quadicon is not available
    quad_icon = item.try(:decorate).try(:single_quad) if quad_icon.nil? && quad_method == :quadicon

    # Alter the quadicon's bottom-right quadrant on the policy simulation screen
    if !!@policy_sim && session[:policies].present?
      quad_icon = policy_sim(quad_icon, item.passes_profiles?(session[:policies].keys))
    end

    quadicon_output(quad_icon) if quad_icon
  end
end
