keyrows = {}

WikiPage.all.each do |w|
    keyrows["wiki_page_#{w.id}_views"] = w.title
end
Quiz.all.each do |q|
    keyrows["quiz_#{q.id}_views"] = "V: #{q.title}"
    keyrows["quiz_#{q.id}_participation"] = "P: #{q.title}"
end
kcsv = ""

keyrows.each do |k|
        kcsv +=  "#{CSV.generate_line(k)}
"
end

rows = []
course = Course.find(2)
course.users.each do |u|
    row = {}
    row[:id] = u.id
    row[:name] = u.name
    row[:created_at] = u.created_at
    WikiPage.all.each do |w|
        row["wiki_page_#{w.id}_views"] = "0"
    end
    Quiz.all.each do |q|
        row["quiz_#{q.id}_views"] = "0"
        row["quiz_#{q.id}_participation"] = "0"
    end
    AssetUserAccess.for_user(u).for_context(course).each do |a|
        if row.has_key? "#{a.asset_code}_views"
            row["#{a.asset_code}_views"] = a.view_score
        end
        if row.has_key? "#{a.asset_code}_participation"
            row["#{a.asset_code}_participation"] = a.participate_score
        end
    end
    rows.push row
end

require 'csv'

csv = ""

csv += "#{CSV.generate_line(rows.first.map{|k,v| keyrows.has_key?(k) ? keyrows[k] : k})}
"

rows.each do |row|
    srow = []
    rows.first.each do |k,v|
        srow << row[k]
    end
    csv +=  "#{CSV.generate_line(srow)}
"
end

File.open("/tmp/report.csv", 'w') {|f| f.write(csv) }
