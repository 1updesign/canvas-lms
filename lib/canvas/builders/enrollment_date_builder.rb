#
# Copyright (C) 2011 - 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Canvas::Builders
class EnrollmentDateBuilder
  attr_reader :enrollment_dates

  def initialize(enrollment)
    @enrollment = enrollment
    @course = @enrollment.course
    @section = @enrollment.course_section
    @term = @enrollment.course ? @enrollment.course.enrollment_term : nil
    @enrollment_dates = []
  end

  def self.build(enrollment)
    EnrollmentDateBuilder.new(enrollment).build
  end

  def build
    Rails.cache.fetch([@enrollment, @course, 'enrollment_date_ranges'].cache_key) do
      if enrollment_is_restricted?
        add_enrollment_dates(@enrollment, false)
      elsif section_is_restricted?
        add_enrollment_dates(@section)
      elsif course_is_restricted?
        add_enrollment_dates(@course)
      else
        add_term_dates
      end

      @enrollment_dates
    end
  end

  private

  def default_dates
    [nil, nil]
  end

  def term_dates
    @term ? @term.enrollment_dates_for(@enrollment) : default_dates
  end

  def add_enrollment_dates(context, with_term_dates=true)
    @enrollment_dates << [context.start_at, context.end_at]
    @enrollment_dates << term_dates if with_term_dates && is_admin_and_has_term_dates?
  end

  # Also consider term dates unless no term dates are set so that teacher
  # enrollments are 'active' past the course dates if there are term dates
  def is_admin_and_has_term_dates?
    @enrollment.admin? && term_dates != default_dates
  end

  def add_term_dates
     @enrollment_dates << term_dates
  end

  def course_is_restricted?
    @course && @course.restrict_enrollments_to_course_dates
  end

  def section_is_restricted?
    @section && @section.restrict_enrollments_to_section_dates
  end

  def enrollment_is_restricted?
    @enrollment.start_at && @enrollment.end_at
  end
end
end