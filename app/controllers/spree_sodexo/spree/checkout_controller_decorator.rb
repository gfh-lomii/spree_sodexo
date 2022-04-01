module SpreeSodexo::Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :pay_with_sodexo, only: :update
    end

    private

    def pay_with_sodexo
      return unless params[:state] == 'payment'
      return if params[:order].blank? || params[:order][:payments_attributes].blank?

      pm_id = params[:order][:payments_attributes].first[:payment_method_id]
      payment_method = Spree::PaymentMethod.find(pm_id)

      if payment_method && payment_method.kind_of?(Spree::PaymentMethod::Sodexo)
        payment_number = sodexo_create_payment(payment_method)
        sodexo_error && return unless payment_number.present?

        url = URI(payment_method.preferences[:sodexo_url] + "/orders")

        http = Net::HTTP.new(url.host, url.port,
          p_addr = 'us-east-static-04.quotaguard.com',
          p_port = 9293,
          p_user = '6fkr3qsa78y7rl',
          p_pass = '71acknpbfp3emxvl5z6pq71elns',
          p_no_proxy = nil
        )

        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        req = Net::HTTP::Post.new(url)
        req["Accept"] = 'application/json'
        req["Content-Type"] = 'application/json'
        req["apikey"] = payment_method.preferences[:sodexo_apikey]

        if @order.withdrawal_first_name.present? && @order.withdrawal_last_name.present?
          f_name = @order&.withdrawal_first_name
          l_name = @order&.withdrawal_last_name
        elsif @order&.bill_address&.firstname.present? || @order&.bill_address&.lastname.present?
          f_name = @order&.bill_address&.firstname
          l_name = @order&.bill_address&.lastname
        else
          f_name = ''
          l_name = ''
        end

        t_amount = @order.total.to_i
        t_tax = @order.total.round

        if Rails.env.production?
          host = 'sodexo.' + request.host
        else
          host = request.host
        end
        
        req.body = {
                          'reference_id': payment_number,
                          'user': {
                            'email': @order.email,
                            'first_name': f_name,
                            'last_name': l_name,

                          },
                          'amount': {
                            'currency': 'CLP',
                            'total': t_amount,
                            'details': {
                              'subtotal': t_amount - t_tax,
                              'fee': 0,
                              'tax': t_tax
                            }
                          },
                          'methods': [
                            'sodexo'
                          ],
                          'items': [
                            {
                              'name': "Orden #{@order.number}",
                              'code': @order.number,
                              'price': t_amount,
                              'unit_price': t_amount,
                              'quantity': 1
                            }
                          ],
                          'description': I18n.t('order_description', name: Spree::Store.current.name),
                          "customs": [
                            {
                              "key": "payments_notify_user",
                              "value": "true"
                            },
                            {
                              "key": "sodexo_expiration_minutes",
                              "value": "-1"
                            }
                          ],
                          'urls': {
                            'return_url': sodexo_successg_url(payment: payment_number),
                            'cancel_url': sodexo_cancel_url(payment: payment_number)
                          },
                          'webhooks': {
                            'webhook_confirm': sodexo_notify_url(host: host),
                            'webhook_reject': sodexo_failure_url(host: host)
                          }
                        }.to_json

        Rails.logger.info "SODEXO#REQ #{req.body}"
        response = http.request(req)

        raise "#{response.read_body.to_s}" if response.code != '201'
        redirect_to JSON.parse(response.body)['redirect_url']
      end

    rescue StandardError => e
      sodexo_error(e)
    end

    def sodexo_create_payment(payment_method)
      payment = @order.payments.build(payment_method_id: payment_method.id, amount: @order.total, state: 'checkout')

      unless payment.save
        flash[:error] = payment.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) && return
      end

      unless payment.pend!
        flash[:error] = payment.errors.full_messages.join("\n")
        redirect_to checkout_state_path(@order.state) && return
      end

      payment.number
    end

    def sodexo_error(e = nil)
      @order.errors[:base] << "sodexo error #{e.try(:message)}"
      render :edit
    end
  end
end

::Spree::CheckoutController.prepend SpreeSodexo::Spree::CheckoutControllerDecorator
