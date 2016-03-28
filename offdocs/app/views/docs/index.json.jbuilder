json.array!(@docs) do |doc|
  json.extract! doc, :id, :title, :source, :source_link, :document, :url
  json.url doc_url(doc, format: :json)
end
