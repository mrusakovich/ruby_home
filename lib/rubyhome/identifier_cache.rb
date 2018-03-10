require 'yaml/store'

module Rubyhome
  class IdentifierCache
    def initialize(store)
      @store = store
      @accessories ||= []
    end

    attr_reader :store
    attr_accessor :accessories

    def save
      store.transaction do
        store[:accessories] = accessories
      end
    end

    def self.pstore=(new_storage)
      @@identifier_cache = IdentifierCache.new(new_storage)
    end

    @@identifier_cache = IdentifierCache.new(YAML::Store.new 'identifier_cache.yml')

    class << self

      def accessories
        @@identifier_cache.accessories
      end

      def services
        accessories.flat_map(&:services)
      end

      def characteristics
        services.flat_map(&:characteristics)
      end

      def find_characteristics(attributes)
        characteristics.select do |characteristic|
          attributes.all? { |key, value| characteristic.send(key) == value }
        end
      end

      def save
        @@identifier_cache.save
      end

      def add_accessory(accessory)
        accessories << accessory.tap do |a|
          a.id = accessories.size + 1
        end

        save
      end

      def add_service(service)
        accessory = service.accessory

        accessory.services << service.tap do |s|
          s.instance_id = accessory.next_available_instance_id
        end

        save
      end

      def add_characteristic(characteristic)
        service = characteristic.service

        service.characteristics << characteristic.tap do |c|
          c.instance_id = characteristic.accessory.next_available_instance_id
        end

        save
      end
    end
  end
end
