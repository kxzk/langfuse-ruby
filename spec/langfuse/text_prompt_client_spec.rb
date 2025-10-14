# frozen_string_literal: true

RSpec.describe Langfuse::TextPromptClient do
  let(:prompt_data) do
    {
      "id" => "prompt-123",
      "name" => "greeting",
      "version" => 1,
      "prompt" => "Hello {{name}}!",
      "type" => "text",
      "labels" => ["production"],
      "tags" => ["customer-facing"],
      "config" => { "temperature" => 0.7 }
    }
  end

  describe "#initialize" do
    it "creates a text prompt client" do
      client = described_class.new(prompt_data)
      expect(client).to be_a(described_class)
    end

    it "sets the name" do
      client = described_class.new(prompt_data)
      expect(client.name).to eq("greeting")
    end

    it "sets the version" do
      client = described_class.new(prompt_data)
      expect(client.version).to eq(1)
    end

    it "sets the prompt" do
      client = described_class.new(prompt_data)
      expect(client.prompt).to eq("Hello {{name}}!")
    end

    it "sets the labels" do
      client = described_class.new(prompt_data)
      expect(client.labels).to eq(["production"])
    end

    it "sets the tags" do
      client = described_class.new(prompt_data)
      expect(client.tags).to eq(["customer-facing"])
    end

    it "sets the config" do
      client = described_class.new(prompt_data)
      expect(client.config).to eq({ "temperature" => 0.7 })
    end

    it "defaults labels to empty array when not provided" do
      data = prompt_data.dup.tap { |d| d.delete("labels") }
      client = described_class.new(data)
      expect(client.labels).to eq([])
    end

    it "defaults tags to empty array when not provided" do
      data = prompt_data.dup.tap { |d| d.delete("tags") }
      client = described_class.new(data)
      expect(client.tags).to eq([])
    end

    it "defaults config to empty hash when not provided" do
      data = prompt_data.dup.tap { |d| d.delete("config") }
      client = described_class.new(data)
      expect(client.config).to eq({})
    end

    context "with invalid prompt data" do
      it "raises ArgumentError when prompt_data is not a Hash" do
        expect { described_class.new("not a hash") }.to raise_error(
          ArgumentError, "prompt_data must be a Hash"
        )
      end

      it "raises ArgumentError when prompt field is missing" do
        data = prompt_data.dup.tap { |d| d.delete("prompt") }
        expect { described_class.new(data) }.to raise_error(
          ArgumentError, "prompt_data must include 'prompt' field"
        )
      end

      it "raises ArgumentError when name field is missing" do
        data = prompt_data.dup.tap { |d| d.delete("name") }
        expect { described_class.new(data) }.to raise_error(
          ArgumentError, "prompt_data must include 'name' field"
        )
      end

      it "raises ArgumentError when version field is missing" do
        data = prompt_data.dup.tap { |d| d.delete("version") }
        expect { described_class.new(data) }.to raise_error(
          ArgumentError, "prompt_data must include 'version' field"
        )
      end
    end
  end

  describe "#compile" do
    let(:client) { described_class.new(prompt_data) }

    context "with variables" do
      it "substitutes variables in the template" do
        result = client.compile(variables: { name: "Alice" })
        expect(result).to eq("Hello Alice!")
      end

      it "handles multiple variables" do
        data = prompt_data.merge("prompt" => "{{greeting}} {{name}}, welcome to {{place}}!")
        client = described_class.new(data)
        result = client.compile(variables: { greeting: "Hi", name: "Bob", place: "Langfuse" })
        expect(result).to eq("Hi Bob, welcome to Langfuse!")
      end

      it "handles string keys" do
        result = client.compile(variables: { "name" => "Charlie" })
        expect(result).to eq("Hello Charlie!")
      end

      it "leaves unmatched placeholders in output" do
        result = client.compile(variables: {})
        expect(result).to eq("Hello {{name}}!")
      end
    end

    context "without variables" do
      it "returns the prompt as-is" do
        data = prompt_data.merge("prompt" => "Hello world!")
        client = described_class.new(data)
        result = client.compile(variables: {})
        expect(result).to eq("Hello world!")
      end

      it "returns the prompt with placeholders when no variables provided" do
        result = client.compile(variables: {})
        expect(result).to eq("Hello {{name}}!")
      end
    end

    context "with complex templates" do
      it "handles nested object properties" do
        data = prompt_data.merge("prompt" => "User: {{user.name}}, Email: {{user.email}}")
        client = described_class.new(data)
        result = client.compile(
          variables: {
            user: { name: "Alice", email: "alice@example.com" }
          }
        )
        expect(result).to eq("User: Alice, Email: alice@example.com")
      end

      it "handles conditional sections" do
        data = prompt_data.merge("prompt" => "Hello{{#admin}} Admin{{/admin}}!")
        client = described_class.new(data)

        result_admin = client.compile(variables: { admin: true })
        expect(result_admin).to eq("Hello Admin!")

        result_user = client.compile(variables: { admin: false })
        expect(result_user).to eq("Hello!")
      end

      it "handles list iteration" do
        data = prompt_data.merge("prompt" => "Users: {{#users}}{{name}}, {{/users}}")
        client = described_class.new(data)
        result = client.compile(
          variables: {
            users: [
              { name: "Alice" },
              { name: "Bob" },
              { name: "Charlie" }
            ]
          }
        )
        expect(result).to eq("Users: Alice, Bob, Charlie, ")
      end
    end

    context "with special characters" do
      it "escapes HTML characters by default" do
        data = prompt_data.merge("prompt" => "Message: {{message}}")
        client = described_class.new(data)
        result = client.compile(variables: { message: "<script>alert('hi')</script>" })
        expect(result).to eq("Message: &lt;script&gt;alert(&#39;hi&#39;)&lt;/script&gt;")
      end

      it "escapes quotes but preserves newlines" do
        data = prompt_data.merge("prompt" => "Text: {{text}}")
        client = described_class.new(data)
        result = client.compile(variables: { text: "Line 1\nLine 2\n\"quoted\"" })
        expect(result).to eq("Text: Line 1\nLine 2\n&quot;quoted&quot;")
      end

      it "allows unescaped output with triple braces" do
        data = prompt_data.merge("prompt" => "Message: {{{message}}}")
        client = described_class.new(data)
        result = client.compile(variables: { message: "<script>alert('hi')</script>" })
        expect(result).to eq("Message: <script>alert('hi')</script>")
      end
    end
  end
end
