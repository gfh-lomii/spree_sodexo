module Spree
  class SodexoController < Spree::BaseController
    protect_from_forgery except: [:notify]
    layout 'spree/layouts/redirect', only: :success

    def success
      @payment = Spree::Payment.where(number: params[:payment]).last
      if !@payment.order.completed?
        redirect_to(checkout_state_path(:payment), subdomain: false) and return
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

      payment = Spree::Payment.find_by!(number: ecommerceOrderId)
      payment_method = payment.payment_method

      puts "ecommerceOrderId: #{ecommerceOrderId}"
      puts "multicajaOrderId: #{multicajaOrderId}"

      if ecommerceOrderId == 'PT0Q094U' || ecommerceOrderId == 'POGJJCCR' || ecommerceOrderId =='P487YMZP'
        payment.failure!
        head :ok
        return
      end

      if !validate_api_key(request.headers["HTTP_APIKEY"], ecommerceOrderId, multicajaOrderId, payment_method.preferences[:sodexo_apikey])
       raise "Error en autenticación"
      end

      if !payment.completed?
        payment.complete!
        order = payment.order
        order.skip_stock_validation = true
        payment.order.next!
      end
      head :ok
    rescue
      head :unprocessable_entity
    end

    def failure
      request.body.rewind
      order = JSON.parse request.body.read
      ecommerceOrderId = order['reference_id']
      multicajaOrderId = order['order_id']

      puts "ecommerceOrderId: #{ecommerceOrderId}"
      puts "multicajaOrderId: #{multicajaOrderId}"

      payment = Spree::Payment.find_by!(number: ecommerceOrderId)
      payment_method = payment.payment_method

      if !validate_api_key(request.headers["HTTP_APIKEY"], ecommerceOrderId, multicajaOrderId,
          payment_method.preferences[:sodexo_secret_token])
       raise "Error en autenticación"
      end

      if !payment.completed?
        payment.failure!
      end
      head :ok
    rescue
      head :unprocessable_entity
    end

    def completion_route(order, custom_params = nil) spree.order_path(order, custom_params)
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
