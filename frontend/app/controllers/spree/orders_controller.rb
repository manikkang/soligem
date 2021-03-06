module Spree
  class OrdersController < Spree::StoreController
    before_action :check_authorization
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper 'spree/products', 'spree/orders'

    respond_to :html

    before_filter :assign_order, only: :update
    # note: do not lock the #edit action because that's where we redirect when we fail to acquire a lock
    around_filter :lock_order, only: :update
    before_filter :apply_coupon_code, only: :update
    skip_before_filter :verify_authenticity_token, only: [:populate]

    def show
      @order = Order.find_by_number!(params[:id])
    end

    def update
      if @order.contents.update_cart(order_params)
        respond_with(@order) do |format|
          format.html do
            if params.key?(:checkout)
              @order.next if @order.cart?
              redirect_to checkout_state_path(@order.checkout_steps.first)
            else
              redirect_to cart_path
            end
          end
        end
      else
        respond_with(@order)
      end
    end

    # Shows the current incomplete order from the session
    def edit
      @order = current_order || Order.incomplete.find_or_initialize_by(guest_token: cookies.signed[:guest_token])
      associate_user
    end

    # Adds a new item to the order (creating a new order if none already exists)
    def populate
 
      order   = current_order(create_order_if_necessary: true)
     if params[:sample]=="true"
    @product=Product.find(params[:product_id])
    @variants=@product.variants.select{|b| b.option_values.select{|c| c.id == params[:selected].to_i}.first}
     @variants.each do |variant|
     order.contents.add(variant,1)
    
        
    
     end 
     else
     # 2,147,483,647 is crazy. See issue https://github.com/spree/spree/issues/2695.
      [params[:variant],params[:quantity]].transpose.each do |variant_id,quantity|
       variant = Spree::Variant.find(variant_id)
      order.contents.add(variant, quantity)
   
     end
     
        params[:data].each do |data|
         
          if Labeldatum.exists?( order_id: order.id,optionvalue_label_id: data.first )
          @data=Labeldatum.where(order_id: order.id,optionvalue_label_id: data.first).first
         
          @data.data=data.second
          @data.save

          else
          @data=Labeldatum.new
          @data.order_id=order.id
          @data.optionvalue_label_id=data.first
          @data.data=data.second
          @data.save
        end
        end
         end
      
        respond_with(order) do |format|
          format.html { redirect_to cart_path }
        
     
    end
    end
    
    def empty
      if @order = current_order
        @order.empty!
      end

      redirect_to spree.cart_path
    end

    def accurate_title
      if @order && @order.completed?
        Spree.t(:order_number, number: @order.number)
      else
        Spree.t(:shopping_cart)
      end
    end

    def check_authorization
      cookies.permanent.signed[:guest_token] = params[:token] if params[:token]
      order = Spree::Order.find_by_number(params[:id]) || current_order

      if order
        authorize! :edit, order, cookies.signed[:guest_token]
      else
        authorize! :create, Spree::Order
      end
    end

    private

    def order_params
      if params[:order]
        params[:order].permit(*permitted_order_attributes)
      else
        {}
      end
    end

    def assign_order
      @order = current_order
      unless @order
        flash[:error] = Spree.t(:order_not_found)
        redirect_to(root_path) && return
      end
    end
  end
end
