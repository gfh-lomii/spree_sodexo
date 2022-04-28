module Spree
  class SodexoController < Spree::BaseController
    protect_from_forgery except: [:notify]
    layout 'spree/layouts/redirect', only: :success

    def success
      @payment = Spree::Payment.where(number: params[:payment]).last

      if @payment.blank?
        redirect_to(checkout_state_path(:payment), subdomain: false)
        return
      end

      if @payment.completed?
        if !@payment.order.completed?
          return
        end
      elsif @payment.failed?
        redirect_to(checkout_state_path(:payment), subdomain: false)
        return
      else
        if params[:retry].present? && params[:retry].to_i > 2
          redirect_to(checkout_state_path(:payment), subdomain: false)
          return
        end
        return
      end

      @current_order = nil
      unless SodexoNotification.find_by(order_id: @payment.order_id, payment_id: @payment.id)
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
      end

      SodexoNotification.create(order_id: @payment.order_id, payment_id: @payment.id)
      redirect_to(completion_route(@payment.order), subdomain: false)
    end

    def cancel
      @payment = Spree::Payment.where(number: params[:payment]).last
      redirect_to(checkout_state_path(:payment), subdomain: false) and return
    end

    def notify
      request.body.rewind
      order = JSON.parse request.body.read
      ecommerceOrderId = order['reference_id']
      multicajaOrderId = order['order_id']
      Rails.logger.info "SODEXO#notify lomi_reference_id: #{ecommerceOrderId}, MC_order_id: #{multicajaOrderId}"
      payment = Spree::Payment.find_by(number: ecommerceOrderId)
      if payment.blank?
        Time.zone = 'America/Santiago'
        date = DateTime.now.in_time_zone.strftime("%a, %B %d %T")
        notification_url = 'https://hooks.slack.com/workflows/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'
        message = "[SODEXO SUCCESS] Recibimos el pago pero no se encuentra el pago. payment_number: #{ecommerceOrderId}, multicajaref: #{multicajaOrderId}"
        SlackNotificationsJob.perform_later(notification_url, message)

        head :ok
        return
      end
      payment_method = payment.payment_method

      # puts "ecommerceOrderId: #{ecommerceOrderId}"
      # puts "multicajaOrderId: #{multicajaOrderId}"

      if ecommerceOrderId == 'PT0Q094U' || ecommerceOrderId == 'POGJJCCR' || ecommerceOrderId =='P487YMZP'
        payment.failure!
        head :ok
        return
      end

      if !validate_api_key(request.headers["HTTP_APIKEY"], ecommerceOrderId, multicajaOrderId, payment_method.preferences[:sodexo_apikey])
       raise "Error en autenticación"
      end

      payment.complete! if !payment.completed?
      ConfirmPaymentJob.perform_later(payment.id)

      head :ok
    rescue
      head :unprocessable_entity
    end

    def failure
      request.body.rewind
      order = JSON.parse request.body.read
      ecommerceOrderId = order['reference_id']
      multicajaOrderId = order['order_id']
      Rails.logger.info "SODEXO#failure lomi_reference_id: #{ecommerceOrderId}, MC_order_id: #{multicajaOrderId}"

      # puts "ecommerceOrderId: #{ecommerceOrderId}"
      # puts "multicajaOrderId: #{multicajaOrderId}"

      payment = Spree::Payment.find_by(number: ecommerceOrderId)
      if payment.blank?
        Time.zone = 'America/Santiago'
        date = DateTime.now.in_time_zone.strftime("%a, %B %d %T")
        notification_url = 'https://hooks.slack.com/workflows/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'
        message = "[SODEXO FAIL] No se encuentra el pago. payment_number: #{ecommerceOrderId}, multicajaref: #{multicajaOrderId}"
        SlackNotificationsJob.perform_later(notification_url, message)

        head :ok
        return
      end
      payment_method = payment.payment_method

      if !validate_api_key(request.headers["HTTP_APIKEY"], ecommerceOrderId, multicajaOrderId,
          payment_method.preferences[:sodexo_secret_token])
       raise "Error en autenticación"
      end

      if payment.completed?
        Time.zone = 'America/Santiago'
        date = DateTime.now.in_time_zone.strftime("%a, %B %d %T")
        notification_url = 'https://hooks.slack.com/workflows/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'
        message = "[SODEXO FAIL] Recibimos un rechazo a un pago que ya estaba confirmado, no recibiremos el dinero pero la orden ya fue confirmada. payment_number: #{ecommerceOrderId}, multicajaref: #{multicajaOrderId}"
        SlackNotificationsJob.perform_later(notification_url, message)
      end

      if !payment.completed?
        payment.failure!
      end
      head :ok
    rescue
      head :unprocessable_entity
    end

    def completion_route(order, custom_params = nil) spree.order_path(id: order.number)
    end

    def validate_api_key(headerApikey, referenceId, orderId, apiKey)
      key = referenceId + orderId + apiKey
      puts "key: #{key}"
      hashApiKey = Digest::SHA256.hexdigest(key)
      puts "hashApiKey: #{hashApiKey}"
      puts "headerApikey: #{headerApikey}"
      return hashApiKey == headerApikey
    end
  end
end
