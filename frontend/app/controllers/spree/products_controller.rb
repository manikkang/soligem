module Spree
  class ProductsController < Spree::StoreController
    before_action :load_product, only: :show
    before_action :load_taxon, only: :index

    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    helper 'spree/taxons'

    respond_to :html

    def index
      @searcher = build_searcher(params.merge(include_images: true))
      @products = @searcher.retrieve_products
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end
     def color
      @product=Product.find(params[:product_id])    
      @color=OptionValue.find(params[:color_id])

    end

   def show
      @variants = @product.variants_including_master.active(current_currency).includes([:option_values, :images])
      @product_properties = @product.product_properties.includes(:property)
       @arr = []
      @product.variants.each do |a|
        @arr << a.option_values.select{ |b| b.option_type.id == 2}.first 
      end
     
      @taxon = Spree::Taxon.find(params[:taxon_id]) if params[:taxon_id]
    end
    def label
      @optionvalues= []
    @product=Product.find(params[:product_id]) 
     params[:variants].each do |variant|
     @variant=Variant.find(variant)
    @optionvalues << @variant.option_values.select{|b| b.option_type.id == 4}.first.id
   end



    end

    private

    def accurate_title
      if @product
        @product.meta_title.blank? ? @product.name : @product.meta_title
      else
        super
      end
    end

    def load_product
      if try_spree_current_user.try(:has_spree_role?, "admin")
        @products = Product.with_deleted
      else
        @products = Product.active(current_currency)
      end
      @product = @products.friendly.find(params[:id])
    end

    def load_taxon
      @taxon = Spree::Taxon.find(params[:taxon]) if params[:taxon].present?
    end
  end
end
