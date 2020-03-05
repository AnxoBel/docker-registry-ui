<!--
Copyright (C) 2016-2019 Jones Magloire @Joxit

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
-->
<taglist>
  <!-- Begin of tag -->
  <material-card class="header">
    <div class="material-card-title-action ">
      <material-button waves-center="true" rounded="true" waves-color="#ddd" onclick="registryUI.home();">
        <i class="material-icons">arrow_back</i>
      </material-button>
      <h2>
        Tags of { registryUI.taglist.name }
        <div class="source-hint">
          Sourced from { registryUI.name() + '/' + registryUI.taglist.name }
        </div>
        <div class="item-count">{ registryUI.taglist.tags.length } tags</div>
      </h2>
    </div>
  </material-card>
  <div hide="{ registryUI.taglist.loadend }" class="spinner-wrapper">
    <material-spinner></material-spinner>
  </div>
  <pagination pages="{ registryUI.getPageLabels(this.page, registryUI.getNumPages(registryUI.taglist.tags)) }"></pagination>
  <material-card ref="taglist-tag" class="taglist"
    multi-delete={ this.multiDelete }
    tags={ registryUI.getPage(registryUI.taglist.tags, this.page) }
    show="{ registryUI.taglist.loadend }">
    <table show="{ registryUI.taglist.loadend }" style="border: none;">
      <thead>
      <tr>
        <th
        id="image-date-header"
        class="{registryUI.taglist.imageDateHeaderClassHelper(registryUI.taglist.sorted)}"
        onclick="registryUI.taglist.imageDateHeaderOnClickHelper(registryUI.taglist.sorted);">Creation date
        </th>
        <th>Size</th>
        <th id="image-content-digest-header">Content Digest</th>

        <th
        id="image-tag-header"
        class="{registryUI.taglist.imageTagHeaderClassHelper(registryUI.taglist.sorted)}"
        onclick="registryUI.taglist.imageTagHeaderOnClickHelper(registryUI.taglist.sorted);">Tag
        </th>

        <th class="show-tag-history">History</th>
        <th class={ 'remove-tag': true, delete: this.parent.toDelete > 0 } if="{ registryUI.isImageRemoveActivated }">
          <material-checkbox ref="remove-tag-checkbox" class="indeterminate" show={ this.toDelete === 0} title="Toggle multi-delete. Alt+Click to select all tags."></material-checkbox>
          <material-button waves-center="true" rounded="true" waves-color="#ddd" title="This will delete selected images." onclick={ registryUI.taglist.bulkDelete } show={ this.toDelete > 0 }>
            <i class="material-icons">delete</i>
          </material-button></th>
      </tr>
      </thead>
      <tbody>
      <tr each="{ image in this.opts.tags }">
        <td>
          <image-date image="{ image }"/>
        </td>
        <td>
          <image-size image="{ image }"/>
        </td>
        <td>
          <image-content-digest image="{ image }"/>
          <copy-to-clipboard target="digest" image={ image }/>
        </td>
        <td>
          <image-tag image="{ image }"/>
          <copy-to-clipboard target="tag" image={ image }/>
        </td>
        <td class="show-tag-history">
          <tag-history-button image={ image }/>
        </td>
        <td if="{ registryUI.isImageRemoveActivated }">
          <remove-image multi-delete={ this.opts.multiDelete } image={ image }/>
        </td>
      </tr>
      </tbody>
    </table>
  </material-card>
  <pagination pages="{ registryUI.getPageLabels(this.page, registryUI.getNumPages(registryUI.taglist.tags)) }"></pagination>
  <script>
    var self = registryUI.taglist.instance = this;
    self.page = registryUI.getPageQueryParam();
    registryUI.taglist.tags = [];
    const onResize = function() {
      // window.innerWidth is a blocking access, cache its result.
      const innerWidth = window.innerWidth;
      var chars = 0;
      if (innerWidth >= 1440) {
        chars = 71;
      } else if (innerWidth < 1024) {
        chars = 0;
      } else {
        // SHA256:12345678 + scaled between 1024 and 1440px
        chars = 15 + 56 * ((innerWidth - 1024) / 416);
      }
      registryUI.taglist.tags.map(function (image) {
        image.trigger('content-digest-chars', chars);
      });
    };
    window.addEventListener('resize', onResize);
    // this may be run before the final document size is available, so schedule
    //  a correction once everything is set up.
    window.requestAnimationFrame(onResize);

    this.multiDelete = false;
    this.toDelete = 0;

    this.on('delete', function() {
      if (!registryUI.isImageRemoveActivated || !this.multiDelete) {
        return;
      }
    });

    this.on('multi-delete', function() {
      if (!registryUI.isImageRemoveActivated) {
        return;
      }
      this.multiDelete = !this.multiDelete;
    });

    this.on('toggle-remove-image', function(checked) {
      if (checked) {
        this.toDelete++;
      } else {
        this.toDelete--;
      }

      if (this.toDelete <= 1) {
        this.update();
      }
    });

    this.on('page-update', function(page) {
      self.page = page < 1 ? 1 : page;
      registryUI.updateQueryString(registryUI.getQueryParams({ page: self.page }) );
      this.toDelete = 0;
      this.update();
    });

    this._getRemoveImageTags = function() {
      var images = self.refs['taglist-tag'].tags['remove-image'];
      if (!(images instanceof Array)) {
        images = [images];
      }
      return images;
    };

    registryUI.taglist.bulkDelete = function(e) {
      if (self.multiDelete && self.toDelete > 0) {
        if (e.altKey) {
          self._getRemoveImageTags()
            .filter(function(img) { return img.tags['material-checkbox'].checked; })
            .forEach(function(img) { img.tags['material-checkbox'].toggle() });
        }
        self._getRemoveImageTags().filter(function(img) {
          return img.tags['material-checkbox'].checked;
        }).forEach(function(img) {
          img.delete(true);
        });
      }
    };

    this.on('update', function() {
      var checkbox = this.refs['taglist-tag'].refs['remove-tag-checkbox'];
      if (!checkbox || checkbox._toggle) { return; }

      checkbox._toggle = checkbox.toggle;
      checkbox.toggle = function(e) {
        if (e.altKey) {
          if (!this.checked) { this._toggle(); }
          self._getRemoveImageTags()
            .filter(function(img) { return !img.tags['material-checkbox'].checked; })
            .forEach(function(img) { img.tags['material-checkbox'].toggle() });
        } else {
          this._toggle();
        }
      };

      checkbox.on('toggle', function() {
        registryUI.taglist.instance.multiDelete = this.checked;
        registryUI.taglist.instance.update();
      });
    });

    registryUI.taglist.display = function() {
      registryUI.taglist.tags = [];
      if (route.routeName == 'taglist') {
        const oReq = new Http();
        registryUI.taglist.instance.update();
        oReq.addEventListener('load', function() {
          registryUI.taglist.tags = [];
          if (this.status == 200) {
            const tags = JSON.parse(this.responseText).tags || [];
            registryUI.taglist.tags = tags.map(function(tag) {
              return new registryUI.DockerImage(registryUI.taglist.name, tag);
            }).sort(registryUI.DockerImage.compare);
            window.requestAnimationFrame(onResize);
            self.trigger('page-update', Math.min(self.page, registryUI.getNumPages(registryUI.taglist.tags)))
          } else if (this.status == 404) {
            registryUI.snackbar('Server not found', true);
          } else {
            registryUI.snackbar(this.responseText, true);
          }
        });
        oReq.addEventListener('error', function() {
          registryUI.snackbar(this.getErrorMessage(), true);
          registryUI.taglist.tags = [];
        });
        oReq.addEventListener('loadend', function() {
          registryUI.taglist.loadend = true;
          registryUI.taglist.instance.update();
        });
        oReq.open('GET', registryUI.url() + '/v2/' + registryUI.taglist.name + '/tags/list');
        oReq.send();
        registryUI.taglist.sorted = 'tag-asc';
      }
    };
    registryUI.taglist.display();
    registryUI.taglist.instance.update();

    registryUI.taglist.sort = function(order) {
      switch(order) {
        case 'tag-asc':
          registryUI.taglist.tags.sort(registryUI.DockerImage.compare);
          break;
        case 'tag-desc':
          registryUI.taglist.tags.sort(registryUI.DockerImage.compare);
          registryUI.taglist.tags.reverse();
          break;
        case 'date-asc':
          registryUI.taglist.tags.sort(registryUI.taglist.dateCompare);
          break;
        case 'date-desc':
          registryUI.taglist.tags.sort(registryUI.taglist.dateCompare);
          registryUI.taglist.tags.reverse();
          break;
        default:
          // Empty for the moment
      } 

      registryUI.taglist.sorted = order;
      registryUI.taglist.instance.update();
    };

    /*
     * https://stackoverflow.com/questions/492994/compare-two-dates-with-javascript
     */
    registryUI.taglist.convertToDate = function(d) {
        // Converts the date in d to a date-object. The input can be:
        //   a date object: returned without modification
        //  an array      : Interpreted as [year,month,day]. NOTE: month is 0-11.
        //   a number     : Interpreted as number of milliseconds
        //                  since 1 Jan 1970 (a timestamp) 
        //   a string     : Any format supported by the javascript engine, like
        //                  "YYYY/MM/DD", "MM/DD/YYYY", "Jan 31 2009" etc.
        //  an object     : Interpreted as an object with year, month and date
        //                  attributes.  **NOTE** month is 0-11.
        return (
            d.constructor === Date ? d :
            d.constructor === Array ? new Date(d[0],d[1],d[2]) :
            d.constructor === Number ? new Date(d) :
            d.constructor === String ? new Date(d) :
            typeof d === "object" ? new Date(d.year,d.month,d.date) :
            NaN
        );
    }

    registryUI.taglist.dateCompare = function(a,b) {
        // Compare two dates (could be of any type supported by the convert
        // function above) and returns:
        //  -1 : if a < b
        //   0 : if a = b
        //   1 : if a > b
        // NaN : if a or b is an illegal date
        // NOTE: The code inside isFinite does an assignment (=).
        return (
            isFinite(a=registryUI.taglist.convertToDate(a.creationDate).valueOf()) &&
            isFinite(b=registryUI.taglist.convertToDate(b.creationDate).valueOf()) ?
            (a>b)-(a<b) :
            NaN
        );
    }

    registryUI.taglist.imageDateHeaderClassHelper = function(currentSort) {
        if (currentSort == 'date-asc') {
            return 'material-card-th-sorted-ascending';
        } else if (currentSort == 'date-desc') {
            return 'material-card-th-sorted-descending';
        } else {
            return '';
        }
    }

    function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    registryUI.taglist.imageDateHeaderOnClickHelper = async function(currentSort) {
        if (registryUI.taglist.loaded == undefined) {
          while (registryUI.taglist.tags.some(image => image.creationDate == undefined)) {
            await sleep(100);
          }
	      registryUI.taglist.loaded = true;
        }
        if (currentSort == 'date-asc') {
            registryUI.taglist.sort('date-desc');
        } else {
            registryUI.taglist.sort('date-asc');
        }
    }

    registryUI.taglist.imageTagHeaderClassHelper = function(currentSort) {
        if (currentSort == 'tag-asc') {
            return 'material-card-th-sorted-ascending';
        } else if (currentSort == 'tag-desc') {
            return 'material-card-th-sorted-descending';
        } else {
            return '';
        }
    }

    registryUI.taglist.imageTagHeaderOnClickHelper = function(currentSort) {
        if (currentSort == 'tag-asc') {
            registryUI.taglist.sort('tag-desc');
        } else {
            registryUI.taglist.sort('tag-asc');
        }
    }

  </script>
  <!-- End of tag -->
</taglist>
