desc 'send weekly updates'

task send_weekly_updates: :environment do
	@users = User.where("subscription = 1")
	@update_list = Doc.where("updated_at > ?", 7.days.ago).take(10)
	@users.each do |user|
		Usermailer.send_updates(user, @update_list).deliver_now
	end
end