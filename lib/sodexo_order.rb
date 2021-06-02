class SodexoOrder
  include Rails.application.routes.url_helpers
  def self.description
    description = I18n.t('order_description', name: Spree::Store.current.name)
    I18n.transliterate(description)
  end

  def self.currency(order)
    order.currency
  end

  def self.amount(order)
    order.total.to_i
  end

  # @option opts [String] :transaction_id Identificador propio de la  transacción. Ej: número de factura u orden de compra
  # @option opts [String] :custom Parámetro para enviar información personalizada de la transacción. Ej: documento XML con el detalle del carro de compra
  # @option opts [String] :body Descripción del cobro
  # @option opts [String] :bank_id Identificador del banco para usar en el pago
  # @option opts [String] :return_url La dirección URL a donde enviar al cliente mientras el pago está siendo verificado
  # @option opts [String] :cancel_url La dirección URL a donde enviar al cliente si decide no hacer hacer la transacción
  # @option opts [String] :picture_url Una dirección URL de una foto de tu producto o servicio
  # @option opts [String] :notify_url La dirección del web-service que utilizará sodexo para notificar cuando el pago esté conciliado
  # @option opts [String] :contract_url La dirección URL del archivo PDF con el contrato a firmar mediante este pago. El cobrador debe estar habilitado para este servicio y el campo &#39;fixed_payer_personal_identifier&#39; es obgligatorio
  # @option opts [String] :notify_api_version Versión de la API de notifiaciones para recibir avisos por web-service
  # @option opts [DateTime] :expires_date Fecha de expiración del cobro. Pasada esta fecha el cobro es inválido. Formato ISO-8601. Ej: 2017-03-01T13:00:00Z
  # @option opts [BOOLEAN] :send_email Si es &#39;true&#39;, se enviará una solicitud de cobro al correo especificado en &#39;payer_email&#39;
  # @option opts [String] :payer_name Nombre del pagador. Es obligatorio cuando send_email es &#39;true&#39;
  # @option opts [String] :payer_email Correo del pagador. Es obligatorio cuando send_email es &#39;true&#39;
  # @option opts [BOOLEAN] :send_reminders Si es &#39;true&#39;, se enviarán recordatorios de cobro.
  # @option opts [String] :responsible_user_email Correo electrónico del responsable de este cobro, debe corresponder a un usuario sodexo con permisos para cobrar usando esta cuenta de cobro
  # @option opts [String] :fixed_payer_personal_identifier Identificador personal. Si se especifica, solo podrá ser pagado usando ese identificador
  # @option opts [Float] :integrator_fee Comisión para el integrador. Sólo es válido si la cuenta de cobro tiene una cuenta de integrador asociada
  # @option opts [BOOLEAN] :collect_account_uuid Para cuentas de cobro con más cuenta propia. Permite elegir la cuenta donde debe ocurrir la transferencia.
  # @option opts [String] :confirm_timeout_date Fecha de rendición del cobro. Es también la fecha final para poder reembolsar el cobro. Formato ISO-8601. Ej: 2017-03-01T13:00:00Z
  # @option opts [String] :mandatory_payment_method Si se especifica, el cobro sólo se podrá pagar utilizando ese medio de pago. El valor para el campo de obtiene consultando el endpoint &#39;Consulta medios de pago disponibles&#39;.


  def self.options(order, payment_id, order_url, notify_url, cancel_url)

    description = I18n.t('order_description', name: Spree::Store.current.name)
    description = I18n.transliterate(description)
    payer_name = order.bill_address.firstname + ' ' + order.bill_address.lastname

    {
      transaction_id: payment_id, # Identificador propio de la  transacción. Ej: número de factura u orden de compra
      custom: '', # Parámetro para enviar información personalizada de la transacción. Ej: documento XML con el detalle del carro de compra
      body: description, # Descripción del cobro
      return_url: order_url, # La dirección URL a donde enviar al cliente mientras el pago está siendo verificado
      cancel_url: cancel_url, # La dirección URL a donde enviar al cliente si decide no hacer hacer la transacción
      notify_url: notify_url, # La dirección del web-service que utilizará sodexo para notificar cuando el pago esté conciliado
      expires_date: '', # [DateTime] Fecha de expiración del cobro. Pasada esta fecha el cobro es inválido. Formato ISO-8601. Ej: 2017-03-01T13:00:00Z
      payer_name: payer_name, # Nombre del pagador. Es obligatorio cuando send_email es &#39;true&#39;
      payer_email: order.email, # Correo del pagador. Es obligatorio cuando send_email es &#39;true&#39;
    }
  end
end
