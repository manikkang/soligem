module Spree
  module Admin
    class PapersController < ResourceController
      def model_class
        Paper
        end
      def index
      	@papers=Paper.all
      end
      end
   end
end    