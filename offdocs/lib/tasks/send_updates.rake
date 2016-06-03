desc 'send updates'

task send_updates: :environment do
	@users = User.where("subscription = 2")
	@update_list = Doc.where("updated_at > ?", 1.day.ago).take(10)
	@users.each do |user|
		Usermailer.send_updates(user, @update_list).deliver_now
	end
end