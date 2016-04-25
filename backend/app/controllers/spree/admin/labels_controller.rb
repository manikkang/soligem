module Spree
  module Admin
    class LabelsController < ResourceController
      def model_class
        Label
        end
      def index
      	@labels=Label.all
      end
      end
   end
end    	