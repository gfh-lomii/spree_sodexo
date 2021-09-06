module Spree
  class PaymentMethod::Sodexo < Spree::PaymentMethod

    preference :sodexo_url, :string
    preference :sodexo_apikey, :string

    def payment_profiles_supported?
      false
    end

    def cancel(*)
    end

    def source_required?
      false
    end

    def credit(*)
      self
    end

    def success?
      true
    end

    def authorization
      self
    end

    def available_for_order?(_order)
      return false if _order.products.with_alcohol_restriction.exists?
      true
    rescue
      return true
    end
  end
end
