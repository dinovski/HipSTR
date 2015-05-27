#ifndef BASE_QUALITY_H_
#define BASE_QUALITY_H_

#include <assert.h>
#include <iostream>
#include <string>
#include <vector>

#include "error.h"
#include "math.h"


#define LOG_10 log(10)
#define LOG_3  log(3)

class BaseQuality {
 public:
  // Based on the Illumina 1.8 Phred+33 system
  const static char MIN_BASE_QUALITY = '!';
  const static char MAX_BASE_QUALITY = 'J';

 private:
  const static int MAX_QUAL_INDEX = MAX_BASE_QUALITY - MIN_BASE_QUALITY;

  // Log likelihoods for quality scores
  double log_correct_[256];
  double log_error_[256];

 public:
  BaseQuality(){
    // Precalculate log likelihoods
    log_correct_[0] = -100000;
    log_error_[0]   = -LOG_3;

    for (int i = 1; i <= MAX_QUAL_INDEX; ++i){
      log_correct_[i] = log(1.0 - pow(10.0, i/(-10.0)));
      log_error_[i]   = log(pow(10.0, i/(-10.0))/3.0);
    }
  }

  /*
   * Returns the log likelihood that the base with the
   * provided quality score should match a different base
   */
  double log_prob_error(char quality) {
    int qual_index = quality - MIN_BASE_QUALITY;
    if (quality < MIN_BASE_QUALITY){
      //std::cerr << "WARNING: Base quality " << quality << " outside of expected range. Proceeding using minimum expected score " << std::endl; 
      return log_error_[0];
    }
    else if (quality > MAX_BASE_QUALITY) {
      //std::cerr << "WARNING: Base quality " << quality << " outside of expected range. Proceeding using maximum expected score " << std::endl;
      return log_error_[MAX_QUAL_INDEX];
    }
    else
      return log_error_[qual_index];
  }


  /*
   * Returns the log likelihood that the base with the
   * provided quality score was observed without error
   */  
  double log_prob_correct(char quality){
    int qual_index = quality - MIN_BASE_QUALITY;
    if (quality < MIN_BASE_QUALITY){
      ///std::cerr << "WARNING: Base quality " << quality << " outside of expected range. Proceeding using minimum expected score " << std::endl; 
      return log_correct_[0];
    }
    else if (quality > MAX_BASE_QUALITY) {
      //std::cerr << "WARNING: Base quality " << quality << " outside of expected range. Proceeding using maximum expected score " << std::endl;
      return log_correct_[MAX_QUAL_INDEX];
    }
    else
      return log_correct_[qual_index];
  }

  char closest_char(double log_prob_e){
    int index = (int)floor(-10*(log_prob_e+LOG_3)/LOG_10);
    assert(index >= 0 && index <= MAX_QUAL_INDEX);
    return index + MIN_BASE_QUALITY;
  }

  std::string average_base_qualities(std::vector<const std::string*> base_qualities);
};

#endif
