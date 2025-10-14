# frozen_string_literal: true

RSpec.describe Langfuse::Config do
  describe "#initialize" do
    it "sets default values" do
      config = described_class.new

      expect(config.base_url).to eq("https://cloud.langfuse.com")
      expect(config.timeout).to eq(5)
      expect(config.cache_ttl).to eq(60)
      expect(config.cache_max_size).to eq(1000)
      expect(config.cache_backend).to eq(:memory)
    end

    it "reads from environment variables" do
      ENV["LANGFUSE_PUBLIC_KEY"] = "test_public"
      ENV["LANGFUSE_SECRET_KEY"] = "test_secret"
      ENV["LANGFUSE_BASE_URL"] = "https://custom.langfuse.com"

      config = described_class.new

      expect(config.public_key).to eq("test_public")
      expect(config.secret_key).to eq("test_secret")
      expect(config.base_url).to eq("https://custom.langfuse.com")
    ensure
      ENV.delete("LANGFUSE_PUBLIC_KEY")
      ENV.delete("LANGFUSE_SECRET_KEY")
      ENV.delete("LANGFUSE_BASE_URL")
    end

    it "accepts block for configuration" do
      config = described_class.new do |c|
        c.public_key = "block_public"
        c.secret_key = "block_secret"
        c.cache_ttl = 120
      end

      expect(config.public_key).to eq("block_public")
      expect(config.secret_key).to eq("block_secret")
      expect(config.cache_ttl).to eq(120)
    end

    it "creates a default logger" do
      config = described_class.new
      expect(config.logger).to be_a(Logger)
    end
  end

  describe "#validate!" do
    let(:config) do
      described_class.new do |c|
        c.public_key = "pk_test"
        c.secret_key = "sk_test"
      end
    end

    it "passes validation with valid configuration" do
      expect { config.validate! }.not_to raise_error
    end

    context "when public_key is missing" do
      it "raises ConfigurationError" do
        config.public_key = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "public_key is required"
        )
      end

      it "raises ConfigurationError when empty" do
        config.public_key = ""
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "public_key is required"
        )
      end
    end

    context "when secret_key is missing" do
      it "raises ConfigurationError" do
        config.secret_key = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "secret_key is required"
        )
      end

      it "raises ConfigurationError when empty" do
        config.secret_key = ""
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "secret_key is required"
        )
      end
    end

    context "when base_url is invalid" do
      it "raises ConfigurationError when nil" do
        config.base_url = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "base_url cannot be empty"
        )
      end

      it "raises ConfigurationError when empty" do
        config.base_url = ""
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "base_url cannot be empty"
        )
      end
    end

    context "when timeout is invalid" do
      it "raises ConfigurationError when nil" do
        config.timeout = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "timeout must be positive"
        )
      end

      it "raises ConfigurationError when zero" do
        config.timeout = 0
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "timeout must be positive"
        )
      end

      it "raises ConfigurationError when negative" do
        config.timeout = -1
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "timeout must be positive"
        )
      end
    end

    context "when cache_ttl is invalid" do
      it "raises ConfigurationError when nil" do
        config.cache_ttl = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "cache_ttl must be non-negative"
        )
      end

      it "raises ConfigurationError when negative" do
        config.cache_ttl = -1
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "cache_ttl must be non-negative"
        )
      end

      it "allows zero (disabled cache)" do
        config.cache_ttl = 0
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when cache_max_size is invalid" do
      it "raises ConfigurationError when nil" do
        config.cache_max_size = nil
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "cache_max_size must be positive"
        )
      end

      it "raises ConfigurationError when zero" do
        config.cache_max_size = 0
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "cache_max_size must be positive"
        )
      end

      it "raises ConfigurationError when negative" do
        config.cache_max_size = -1
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          "cache_max_size must be positive"
        )
      end
    end

    context "when cache_backend is invalid" do
      it "raises ConfigurationError for unknown backend" do
        config.cache_backend = :redis
        expect { config.validate! }.to raise_error(
          Langfuse::ConfigurationError,
          /cache_backend must be one of/
        )
      end

      it "allows :memory backend" do
        config.cache_backend = :memory
        expect { config.validate! }.not_to raise_error
      end

      it "allows :rails backend" do
        config.cache_backend = :rails
        expect { config.validate! }.not_to raise_error
      end
    end
  end

  describe "attribute setters" do
    let(:config) { described_class.new }

    it "allows setting public_key" do
      config.public_key = "new_key"
      expect(config.public_key).to eq("new_key")
    end

    it "allows setting secret_key" do
      config.secret_key = "new_secret"
      expect(config.secret_key).to eq("new_secret")
    end

    it "allows setting base_url" do
      config.base_url = "https://custom.com"
      expect(config.base_url).to eq("https://custom.com")
    end

    it "allows setting timeout" do
      config.timeout = 10
      expect(config.timeout).to eq(10)
    end

    it "allows setting cache_ttl" do
      config.cache_ttl = 300
      expect(config.cache_ttl).to eq(300)
    end

    it "allows setting cache_max_size" do
      config.cache_max_size = 5000
      expect(config.cache_max_size).to eq(5000)
    end

    it "allows setting cache_backend" do
      config.cache_backend = :rails
      expect(config.cache_backend).to eq(:rails)
    end

    it "allows setting logger" do
      custom_logger = Logger.new($stdout)
      config.logger = custom_logger
      expect(config.logger).to eq(custom_logger)
    end
  end
end
