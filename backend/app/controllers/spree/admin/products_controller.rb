module Spree
  module Admin
    class ProductsController < ResourceController
      helper 'spree/products'

      before_filter :load_data, except: [:index]
      create.before :create_before
      update.before :update_before
      helper_method :clone_object_url

      def show
        redirect_to action: :edit
      end

      def index
        session[:return_to] = request.url
        respond_with(@collection)
      end
      def abc
        @arr = []
        @product=Product.friendly.find(params[:id])
       @product.variants.each do |a|
        @arr << a.option_values.select{ |b| b.option_type.id == 4}.first 

      end
      @label=Label.all
      end
      def cde
        
        params[:lab].each do |a|
          b=a.first
          a.second.each do |c|
           
            @ov=OptionvalueLabel.new
            @ov.product_id = Product.friendly.find(params[:id]).id
            @ov.label_id = c
            @ov.option_value_id = b
            @ov.save
            end
        end
       redirect_to edit_admin_product_path(params[:id]) 
      end
      def paper
       
        @product=Product.friendly.find(params[:id])
        @papers=Paper.all
      end
      def papersave
        byebug
        params[:paper].each do |paper|
        @paperproduct=Paperproduct.new
        @paperproduct.paper_id=paper
        @paperproduct.product_id=@product.id
        @paperproduct.save
        end
        redirect_to edit_admin_product_path(params[:id]) 
      end
      def update
     
        if params[:product][:taxon_ids].present?
          params[:product][:taxon_ids] = params[:product][:taxon_ids].split(',')
        end
        if params[:product][:option_type_ids].present?
          params[:product][:option_type_ids] = params[:product][:option_type_ids].split(',')
        end
        if updating_variant_property_rules?
          params[:product][:variant_property_rules_attributes].each do |_index, param_attrs|
            param_attrs[:option_value_ids] = param_attrs[:option_value_ids].split(',')
          end
        end
        if params[:product][:status].present?
         if params[:product][:status] == "true"
           if params[:product][:taxon_ids].present?
                 @taxon=Spree::Taxon.find(params[:product][:taxon_ids]).first
                  @taxon.status = true
                  @taxon.save
            end
          end
          
         end
        invoke_callbacks(:update, :before)
        if @object.update_attributes(permitted_resource_params)
  
          if params[:product][:status].present?
          if params[:product][:status] == "false"
             @taxon=Spree::Taxon.find(params[:product][:taxon_ids]).first
          if @taxon.products.select{|b| b.status==true}.present?
             @taxon.status = true
          else
              @taxon.status = false
              @taxon.save
          end
          end
         end
          invoke_callbacks(:update, :after)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          respond_with(@object) do |format|
            format.html { redirect_to location_after_save }
            format.js   { render layout: false }
          end
        else
          # Stops people submitting blank slugs, causing errors when they try to
          # update the product again
          @product.slug = @product.slug_was if @product.slug.blank?
          invoke_callbacks(:update, :fails)
          respond_with(@object)
        end
      end

      def destroy
        @product = Product.friendly.find(params[:id])
        @product.destroy

        flash[:success] = Spree.t('notice_messages.product_deleted')

        respond_with(@product) do |format|
          format.html { redirect_to collection_url }
          format.js { render_js_for_destroy }
        end
      end

      def clone
        @new = @product.duplicate

        if @new.save
          flash[:success] = Spree.t('notice_messages.product_cloned')
        else
          flash[:error] = Spree.t('notice_messages.product_not_cloned')
        end

        redirect_to edit_admin_product_url(@new)
      end

      private

      def find_resource
        Product.with_deleted.friendly.find(params[:id])
      end

      def location_after_save
        if updating_variant_property_rules?
          url_params = {}
          url_params[:ovi] = []
          params[:product][:variant_property_rules_attributes].each do |_index, param_attrs|
            url_params[:ovi] += param_attrs[:option_value_ids]
          end
          spree.admin_product_product_properties_url(@product, url_params)
        else
          spree.edit_admin_product_url(@product)
        end
      end

      def load_data
        @taxons = Taxon.order(:name)
        @option_types = OptionType.order(:name)
        @tax_categories = TaxCategory.order(:name)
        @shipping_categories = ShippingCategory.order(:name)
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:deleted_at_null] ||= "1"

        params[:q][:s] ||= "name asc"
        @collection = super
        @collection = @collection.with_deleted if params[:q].delete(:deleted_at_null) == '0'
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
              distinct_by_product_ids(params[:q][:s]).
              includes(product_includes).
              page(params[:page]).
              per(Spree::Config[:admin_products_per_page])

        @collection
      end

      def create_before
        return if params[:product][:prototype_id].blank?
        @prototype = Spree::Prototype.find(params[:product][:prototype_id])
      end

      def update_before
        # note: we only reset the product properties if we're receiving a post
        #       from the form on that tab
        return unless params[:clear_product_properties]
        params[:product] ||= {}
      end

      def product_includes
        [{ variants: [:images], master: [:images, :default_price] }]
      end

      def clone_object_url(resource)
        clone_admin_product_url resource
      end

      def variant_stock_includes
        [:images, stock_items: :stock_location, option_values: :option_type]
      end

      def variant_scope
        @product.variants
      end

      def updating_variant_property_rules?
        params[:product][:variant_property_rules_attributes].present?
      end
    end
  end
end
