# About Melody Maker

Melody Maker introduces a completely new user experience and design for Melody. Right now it is in its very early stages of development. To install and use Melody Maker you will first need to:

* Download or clone from github the melody-1.1 branch from byrnereese's github account.

**Downloading Melody 1.1**

* https://github.com/byrnereese/melody/zipball/melody-1.1

**Cloning Melody 1.1 from Github**

If you are familiar with using git, this can be done this way:

    prompt> git clone git@github.com:byrnereese/melody.git
    prompt> cd melody
    prompt> git checkout melody-1.1

Once your version of Melody is installed you can install the Melody Maker plugin as you do any Melody Plugin.

*Note: you may need to pull down updates from byrnereese/melody/melody-1.1 as the work on Melody Maker progresses, in order to take advantage of its new features.*

# Status Widgets

Developers can register status widgets that live in the footer of every page. There are two types of status widgets, designating how their contents are determined and/or rendered to the screen:

* **counter widgets** - which comprise a label and a count pill
* **template widgets** - whose contents are determined by a template written by the developer

**Example Counter Widget**

The following widget shows the total number of moderated comments on the current blog:

    status_widgets:
      comments:
        label: Comments
        count_handler: $MelodyMaker::MelodyMaker::Plugin::status_comments
        mode: list_entries
        args:
          filter_key: 'unpublished'

The count handler is a subroutine that looks like this:

    sub status_comments {
        my $app = shift;
        my ($ctx) = @_;
        my $app = MT->instance;
        my $blog = $app->can('blog') ? $app->blog : $ctx->stash('blog');
        my $count = MT->model('comment')->count({
            ($blog ? (blog_id => $blog->id) : ()),
            visible => 0,
            junk_status => MT->model('comment')->NOT_JUNK(),
        });
       return $count;
    }

**Example Template Widget**

Template widgets have less meta data because their contents are wholly derived from the linked template.

    status_widgets:
      some_tmpl_wid:
        template: 'foo.tmpl'

Then `foo.tmpl` might look like this:

   Total Comments <span><mt:BlogCommentCount></span>

The template is automatically seeded with the context of the containing page, which has a blog, author and sometimes an entry context already embedded.

Template widgets will allow developers to create widgets with more complex javascript functionality.

**Conditional Widgets**

Widgets can be made to appear only if specific conditions are present. The following is a widget that will only appear within a blog context.

    status_widgets:
      comments:
        label: Comments
        count_handler: $MelodyMaker::MelodyMaker::Plugin::status_comments
        mode: list_entries
        condition: >>
          sub { return MT->instance->blog; }
