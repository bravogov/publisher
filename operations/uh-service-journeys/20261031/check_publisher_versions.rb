a = Artefact.find_by!(slug: "make-a-freedom-of-information-request")
puts "ARTEFACT: #{a.content_id} #{a.name}"
Edition.where(panopticon_id: a.id).order(version_number: :desc).limit(6).each do |e|
  puts "EDITION: #{e.version_number} #{e.state} body_has_restriction=#{e.editionable.body.to_s.include?("your registered UH Name")}"
end
